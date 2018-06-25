# monkeypatch, see http://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
module Rack
  class Response
    def close
      @body.close if @body.respond_to?(:close)
    end
  end
end

class ApplicationController < ActionController::Base
  include Encoder

  helper_method(
    :available_groups,
    :current_group,
    :current_uid,
    :current_user,
    :current_user_displayname,
    :exceeds_download_size,
    :exceeds_download_size_version,
    :exceeds_download_size_file,
    :has_group_permission?,
    :has_object_permission?,
    :has_session_group_write_permission?,
    :max_download_size_pretty,
    :number_to_storage_size
  )
  protect_from_forgery

  def render_unavailable
    render file: "#{Rails.root}/public/unavailable.html", status: 500
  end

  # there are supposed to be handled by Rails, but 401 is not.
  rescue_from ActiveResource::UnauthorizedAccess do |ex|
    render file: "#{Rails.root}/public/401.html", status: 401, layout: nil
  end

  rescue_from ActiveRecord::RecordNotFound do |ex|
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

  # Returns true if the current user has which permissions on the object.
  def has_group_permission?(group, which)
    group.permission(current_uid).member?(which)
  end

  # Returns true if the current user has which permissions on the object
  def has_object_permission_no_embargo?(object, which)
    has_group_permission?(object.inv_collection.group, which)
  end

  # Returns true if the current user has which permissions on the object with embargo checking
  def has_object_permission?(object, which)
    has_group_permission?(object.inv_collection.group, which) && !in_embargo?(object)
  end

  # Returns true if the user can upload to the session group
  def has_session_group_write_permission?
    has_group_permission?(current_group, 'write')
  end

  # Is object in Embargo?
  def in_embargo?(object)
    @in_embargo = true
    return false if object.inv_embargo.nil?
    if object.inv_embargo.in_embargo?
      @in_embargo = false if has_group_permission?(object.inv_collection.group, 'admin')
    else
      @in_embargo = false
    end
    @in_embargo
  end

  # Return the groups which the user may be a member of
  def available_groups
    groups = current_user.groups.sort_by { |g| g.description.downcase } || []
    groups.map do |group|
      { id: group.id,
        description: group.description,
        permissions: group.permission(current_user.login) }
    end
  end

  private

  # Return the current user. Uses either the session user OR if the
  # user supplied HTTP basic auth info, uses that. Returns nil if
  # there is no session user and HTTP basic auth did not succeed
  def current_user
    unless defined?(@current_user)
      if !session[:uid].nil?
        # normal form login
        @current_user = User.find_by_id(session[:uid])
      else
        # http basic auth
        auth = request.headers['HTTP_AUTHORIZATION']
        if !auth.blank? && auth.match(/Basic /)
          (login, password) = Base64.decode64(auth.gsub(/Basic /, '')).split(/:/)
          @current_user = User.find_by_id(login) if User.valid_ldap_credentials?(login, password)
        end
      end
    end
    @current_user
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

  # @return true if the object is too large for synchronous download, false otherwise
  def exceeds_sync_size(object)
    (object.total_actual_size > APP_CONFIG['max_archive_size'])
  end

  # @return true if the version is too large for synchronous download, false otherwise
  def exceeds_sync_size_version(version)
    (version.total_actual_size > APP_CONFIG['max_archive_size'])
  end

  # @return true if the object is too large even for async download, false otherwise
  def exceeds_download_size(object)
    (object.total_actual_size > APP_CONFIG['max_download_size'])
  end

  # @return true if the version is too large even for async download, false otherwise
  def exceeds_download_size_version(version)
    (version.total_actual_size > APP_CONFIG['max_download_size'])
  end

  # @return true if the file is too large for download, false otherwise
  def exceeds_download_size_file(file)
    (file.full_size > APP_CONFIG['max_download_size'])
  end

  def max_download_size_pretty
    @max_download_size_pretty ||= number_to_storage_size(APP_CONFIG['max_download_size'])
  end

  # Modeled after the rails helper that does all sizes in binary representations
  # but gives sizes in decimal instead with 1kB = 1,000 Bytes, 1 MB = 1,000,000 bytes
  # etc.
  #
  # Formats the bytes in +size+ into a more understandable representation.
  # Useful for reporting file sizes to users. This method returns nil if
  # +size+ cannot be converted into a number. You can change the default
  # precision of 1 in +precision+.
  #
  #  number_to_storage_size(123)           => 123 Bytes
  #  number_to_storage_size(1234)          => 1.2 kB
  #  number_to_storage_size(12345)         => 12.3 kB
  #  number_to_storage_size(1234567)       => 1.2 MB
  #  number_to_storage_size(1234567890)    => 1.2 GB
  #  number_to_storage_size(1234567890123) => 1.2 TB
  #  number_to_storage_size(1234567, 2)    => 1.23 MB
  def number_to_storage_size(size, precision = 1)
    size = Kernel.Float(size)
    if size == 1 then '1 Byte'
    elsif size < 10**3 then format('%d B', size)
    elsif size < 10**6 then format("%.#{precision}f KB", (size / 10.0**3))
    elsif size < 10**9 then format("%.#{precision}f MB", (size / 10.0**6))
    elsif size < 10**12 then format("%.#{precision}f GB", (size / 10.0**9))
    else                    format("%.#{precision}f TB", (size / 10.0**12))
    end.sub('.0', '')
  rescue StandardError
    nil
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # TODO: is this only used for DUAs? if so, let's remove it
  def with_fetched_tempfile(*args)
    require 'open-uri'
    require 'fileutils'
    open(*args) do |data|
      tmp_file = Tempfile.new('mrt_http')
      begin
        until (buff = data.read(4096)).nil?
          tmp_file << buff
        end
        tmp_file.rewind
        yield(tmp_file)
      ensure
        tmp_file.close
        tmp_file.delete
      end
    end
  end

  #:nocov:
  # returns the response of the HTTP request for the DUA URI
  def process_dua_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    uri_response = http.request(Net::HTTP::Get.new(uri.request_uri))
    (uri_response.class == Net::HTTPOK)
  end
  #:nocov:

  def params_u(param)
    urlunencode(params[param])
  end

  def paginate_args
    {
      page: (params[:page] || 1),
      per_page: 10
    }
  end

  def stream_response(url, disposition, filename, mediatype, length = nil)
    response.headers['Content-Type'] = mediatype
    response.headers['Content-Disposition'] = "#{disposition}; filename=\"#{filename}\""
    response.headers['Content-Length'] = length.to_s unless length.nil?
    response.headers['Last-Modified'] = Time.now.httpdate
    self.response_body = Streamer.new(url)
  end

  #:nocov:
  def check_dua(object, redirect_args)
    # bypass DUA processing for python scripts - indicated by special param
    return if params[:blue]

    session[:collection_acceptance] ||= Hash.new(false)
    # check if user already saw DUA and accepted: if so, return
    if session[:collection_acceptance][object.group.id]
      # clear out acceptance if it does not have session persistence
      session[:collection_acceptance].delete(object.group.id) if session[:collection_acceptance][object.group.id] != 'session'
      return
    elsif object.dua_exists? && process_dua_request(object.dua_uri)
      # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
      redirect_to({ controller: 'dua', action: 'index' }.merge(redirect_args)) && return
    end
  end
  #:nocov:

  def is_ark?(str)
    # return !str.match(/ark:\/[0-9]{5}\/[a-z0-9+]/).nil?
    !str.match(/ark:\/[0-9a-zA-Z]{1}[0-9]{4}\/[a-z0-9+]/).nil?
  end
end
