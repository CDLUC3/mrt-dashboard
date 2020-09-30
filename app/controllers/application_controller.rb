# monkeypatch, see http://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
module Rack
  class Response
    def close
      @body.close if @body.respond_to?(:close)
    end
  end
end

class ApplicationController < ActionController::Base
  include DuaMixin
  include Encoder
  include ErrorMixin
  include NumberMixin
  include PaginationMixin
  include HttpMixin

  helper_method(
    :available_groups,
    :current_group,
    :current_uid,
    :current_user,
    :current_user_displayname,
    :current_user_can_download?,
    :current_user_can_write_to_collection?,
    :max_download_size_pretty,
    :number_to_storage_size
  )
  protect_from_forgery

  def render_unavailable
    render file: "#{Rails.root}/public/unavailable.html", status: 500
  end

  # there are supposed to be handled by Rails, but 401 is not.
  rescue_from ActiveResource::UnauthorizedAccess do |_ex|
    render file: "#{Rails.root}/public/401.html", status: 401, layout: nil
  end

  rescue_from ActiveRecord::RecordNotFound do |_ex|
    render file: "#{Rails.root}/public/404.html", status: 404, layout: nil
  end

  helper :all

  # Makes a url of the form /m/ark.../1/file with optionally blank versions and files
  def mk_merritt_url(letter, object, version = nil, file = nil)
    object = Encoder.urlencode(Encoder.urlunencode(object))
    file = file.blank? ? nil : Encoder.urlencode(Encoder.urlunencode(file))
    "/#{letter}/" + [object, version, file].reject(&:blank?).join('/')
  end

  def redirect_to_latest_version
    return unless params[:version].to_i == 0

    ark = InvObject.find_by_ark(params_u(:object))
    latest_version = ark && ark.current_version.number
    # letter = request.path.match(/^\/(.)\//)[1]
    # redirect_to mk_merritt_url(letter, params[:object], latest_version, params[:file])
    # Do not redirect, but just set version to latest
    params[:version] = latest_version.to_s
  end

  def current_user_can_download?(object)
    object.user_can_download?(current_uid)
  end

  # Returns true if the user can upload to the session group
  def current_user_can_write_to_collection?
    session[:group_id] && current_group.user_has_permission?(current_uid, 'write')
  end

  # Return the groups which the user may be a member of
  def available_groups
    @available_groups ||= begin
      current_user.groups
        .sort_by { |g| g.description.downcase }
        .map { |g| { id: g.id, description: g.description, user_permissions: g.user_permissions(current_user.login) } }
    # :nocov:
    rescue StandardError
      []
    end
    # :nocov:
  end

  # Construct a storage key from component parts
  def self.build_storage_key(ark, version = '', file = '')
    key = ark
    key += "|#{version}" unless version == ''
    key += "|#{file}" unless file == ''
    key
  end

  # Encode a storage key constructed from component parts
  def self.encode_storage_key(ark, version = '', file = '')
    return "#{Encoder.urlencode(ark)}/#{version}" if version != '' && file == ''

    key = ApplicationController.build_storage_key(ark, version, file)
    Encoder.urlencode(key)
  end

  def self.add_params_to_path(path, params)
    uri = URI.parse(path)
    uri.query = params.to_query unless params.empty?
    uri.to_s
  end

  def self.get_storage_presign_url(nodekey, has_file: true, params: {})
    base = has_file ? APP_CONFIG['storage_presign_file'] : APP_CONFIG['storage_presign_obj']
    path = File.join(base, 'not-applicable')
    if nodekey.key?(:node_id) && nodekey.key?(:key)
      path = File.join(
        base,
        nodekey[:node_id].to_s,
        nodekey[:key]
      )
    end
    ApplicationController.add_params_to_path(path, params)
  end

  def add_valid_param(dest, source, key, vals)
    return unless source.key?(key)
    return unless source[key].in?(vals)

    dest[key] = source[key]
  end

  def sanitize_presign_params(params)
    sparams = {}
    add_valid_param(sparams, params, 'content', %w[producer full])
    add_valid_param(sparams, params, 'format', %w[zip tar targz])
    sparams
  end

  def create_http_cli(send: 120, connect: 60, receive: 60)
    cli = HTTPClient.new
    cli.connect_timeout = connect
    cli.send_timeout = send
    cli.receive_timeout = receive
    cli
  end

  def presign_get_obj_by_node_key(nodekey, params)
    sparams = sanitize_presign_params(params)
    r = create_http_cli(connect: 20, receive: 20, send: 20).post(
      ApplicationController.get_storage_presign_url(nodekey, has_file: false, params: sparams),
      follow_redirect: true
    )
    eval_presign_obj_by_node_key(r, nodekey[:key])
  rescue HTTPClient::ReceiveTimeoutError
    render status: 408, text: 'Please try your request again later'
  end

  # rubocop:disable all
  def eval_presign_obj_by_node_key(r, key)
    if r.status.in?([ 200, 202 ])
      resp = JSON.parse(r.content)
      render status: r.status , json: resp
    elsif r.status == 403
      render file: "#{Rails.root}/public/403.html", status: 403, layout: nil
    elsif r.status == 404
      render file: "#{Rails.root}/public/404.html", status: 404, layout: nil
    else
      render file: "#{Rails.root}/public/500.html", status: r.status, layout: nil
    end
  end
  # rubocop:enable all

  def presign_obj_by_token
    do_presign_obj_by_token(params[:token], params[:filename], params[:no_redirect])
  end

  def do_presign_obj_by_token(token, filename = 'object.zip', no_redirect = nil)
    r = create_http_cli(connect: 5, receive: 5, send: 5).get(
      File.join(APP_CONFIG['storage_presign_token'], token),
      { contentDisposition: "attachment; filename=#{filename}" },
      {},
      follow_redirect: true
    )
    eval_presign_obj_by_token(r, no_redirect)
  rescue HTTPClient::ReceiveTimeoutError
    render status: 202, text: 'Timeout on request'
  end

  private

  # rubocop:disable all
  def eval_presign_obj_by_token(r, no_redirect = nil)
    if r.status == 200
      resp = JSON.parse(r.content)
      if no_redirect != nil
        render status: 200, json: r.content
        return
      end
      url = resp['url']
      response.headers['Location'] = url
      render status: 303, text: ''
    elsif r.status == 202
      render status: r.status, json: r.content
    elsif r.status == 404
      render file: "#{Rails.root}/public/404.html", status: 404, layout: nil
    else
      render file: "#{Rails.root}/public/500.html", status: r.status, layout: nil
    end
  end
  # rubocop:enable all

  # Return the current user. Uses either the session user OR if the
  # user supplied HTTP basic auth info, uses that. Returns nil if
  # there is no session user and HTTP basic auth did not succeed
  def current_user
    @current_user ||= begin
      User.find_by_id(session[:uid]) || User.from_auth_header(request.headers['HTTP_AUTHORIZATION'])
    end
  end

  # either return the uid from the session OR get the user id from
  # basic auth. Will not hit LDAP unless using basic auth
  def current_uid
    session[:uid] || (current_user && current_user.uid)
  end

  def current_user_displayname
    session[:user_displayname] ||= current_user.displayname
  end

  # if a user is not logged in then it will default to looging them in as a guest user
  # if the object is not public then the user will need to navigate to the login page and
  # login with their own credentials - mstrong 4/12/12
  def require_user
    return if current_uid

    store_location
    flash[:notice] = 'You must be logged in to access the page you requested'
    ret = url_for_with_proto({ controller: 'user_sessions', action: 'guest_login' })
    redirect_to(ret) && return
  end

  # :nocov:
  # TODO: this doesn't seem to be used anywhere; can we delete it?
  def require_user_or_401
    render(status: 401, text: '') && return unless current_user
  end

  # :nocov:

  def current_group
    @_current_group ||= Group.find(session[:group_id])
  end

  def max_download_size_pretty
    @max_download_size_pretty ||= number_to_storage_size(APP_CONFIG['max_download_size'])
  end

  def store_location
    session[:return_to] = url_string_with_proto(request.fullpath)
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def params_u(param)
    Encoder.urlunencode(params[param])
  end

  def stream_response(url, disposition, filename, mediatype, length = nil)
    streamer = Streamer.new(url)
    response.headers['Content-Type'] = mediatype
    response.headers['Content-Disposition'] = "#{disposition}; filename=\"#{filename}\""
    response.headers['Content-Length'] = length.to_s unless length.nil?
    response.headers['Last-Modified'] = Time.now.httpdate
    self.response_body = streamer
  end

  def is_ark?(str)
    str.match?(%r{ark:/[0-9a-zA-Z]{1}[0-9]{4}/[a-z0-9+]})
  end

  def url_for_with_proto(opts)
    opts[:protocol] = 'https' if APP_CONFIG['proto_force'] == 'https'
    url_for(opts)
  end

  def url_string_with_proto(url, force_https: false)
    return url unless force_https || APP_CONFIG['proto_force'] == 'https'

    begin
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
    rescue StandardError
      Rails.logger.error("Url format error caught: #{url}")
    end
  end
end
