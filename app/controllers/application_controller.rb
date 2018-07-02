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
  include NumberMixin

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
    object = urlencode(urlunencode(object))
    file = file.blank? ? nil : urlencode(urlunencode(file))
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
    current_group.user_has_permission?(current_uid, 'write')
  end

  # Return the groups which the user may be a member of
  def available_groups
    groups = current_user.groups.sort_by { |g| g.description.downcase } || []
    groups.map do |group|
      { id:               group.id,
        description:      group.description,
        user_permissions: group.user_permissions(current_user.login) }
    end
  end

  private

  # Return the current user. Uses either the session user OR if the
  # user supplied HTTP basic auth info, uses that. Returns nil if
  # there is no session user and HTTP basic auth did not succeed
  def current_user
    @current_user ||= begin
      user_id = session[:uid] || user_id_from_auth_header_if_valid(request.headers['HTTP_AUTHORIZATION'])
      User.find_by_id(user_id) if user_id
    end
  end

  def user_id_from_auth_header_if_valid(auth_header)
    return unless (match_data = auth_header && auth_header.match(/Basic (.*)/))
    (user_id, password) = Base64.decode64(match_data[1]).split(':')
    user_id if User.valid_ldap_credentials?(user_id, password)
  end

  # either return the uid from the session OR get the user id from
  # basic auth. Will not hit LDAP unless using basic auth
  def current_uid
    session[:uid] || (!current_user.nil? && current_user.uid)
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
    redirect_to(controller: 'user_sessions', action: 'guest_login') && return
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
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def params_u(param)
    urlunencode(params[param])
  end

  def paginate_args
    { page: (params[:page] || 1), per_page: 10 }
  end

  def stream_response(url, disposition, filename, mediatype, length = nil)
    response.headers['Content-Type'] = mediatype
    response.headers['Content-Disposition'] = "#{disposition}; filename=\"#{filename}\""
    response.headers['Content-Length'] = length.to_s unless length.nil?
    response.headers['Last-Modified'] = Time.now.httpdate
    self.response_body = Streamer.new(url)
  end

  def is_ark?(str)
    str.match?(%r{ark:/[0-9a-zA-Z]{1}[0-9]{4}/[a-z0-9+]})
  end
end
