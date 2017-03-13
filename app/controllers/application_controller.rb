# monkeypatch, see http://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
class Rack::Response
  def close
    @body.close if @body.respond_to?(:close)
  end
end

class ApplicationController < ActionController::Base
  include Encoder

  helper_method(:available_groups, :current_user, :current_uid,
                :current_user_displayname, :has_group_permission?,
                :has_object_permission?, :has_session_group_write_permission?,
                :current_group)
  protect_from_forgery

  def render_unavailable
    render :file => "#{Rails.root}/public/unavailable.html", :status => 500
  end

  # there are supposed to be handled by Rails, but 401 is not.
  rescue_from ActiveResource::UnauthorizedAccess do |ex|
    render :file => "public/401", :status => 401, :layout=>nil
  end

  rescue_from ActiveRecord::RecordNotFound do |ex|
    render :file => "public/404", :status => 404, :layout=>nil
  end

  helper :all

  # Makes a url of the form /m/ark.../1/file with optionally blank versions and files
  def mk_merritt_url(letter, object, version=nil, file=nil)
    object = urlencode(urlunencode(object))
    file = if file.blank? then nil else urlencode(urlunencode(file)) end
    "/#{letter}/" + [object, version, file].reject{|x| x.blank?}.join("/")
  end
  
  def redirect_to_latest_version
    if (params[:version].to_i == 0) then
      ark = InvObject.find_by_ark(params_u(:object))
      if ! ark.nil? then
          latest_version = ark.current_version.number
      else
          latest_version = nil
      end
      letter = request.path.match(/^\/(.)\//)[1]
      # redirect_to mk_merritt_url(letter, params[:object], latest_version, params[:file])
      # Do not redirect, but just set version to latest
      params[:version] = latest_version.to_s
    end
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
    has_group_permission?(object.inv_collection.group, which) && ! in_embargo?(object)
  end

  # Returns true if the user can upload to the session group
  def has_session_group_write_permission?
    has_group_permission?(current_group, 'write')
  end
    
  # Is object in Embargo?
  def in_embargo?(object)
    in_embargo = true
    if (object.inv_embargo.nil?) then
       return false
    end
    if (object.inv_embargo.in_embargo?) then
       if (has_group_permission?(object.inv_collection.group, 'admin')) then
          in_embargo = false
       end
    else
       in_embargo = false
    end
    in_embargo
  end

  # Return the groups which the user may be a member of
  def available_groups
    groups = current_user.groups.sort_by{|g| g.description.downcase } || []
    groups.map do |group|
      { :id => group.id, 
        :description => group.description,
        :permissions => group.permission(current_user.login) }
    end
  end

  private

  # Return the current user. Uses either the session user OR if the
  # user supplied HTTP basic auth info, uses that. Returns nil if
  # there is no session user and HTTP basic auth did not succeed
  def current_user
    if !defined?(@current_user) then
      if !session[:uid].nil? then
        # normal form login
        @current_user = User.find_by_id(session[:uid])
      else
        # http basic auth
        auth = request.headers['HTTP_AUTHORIZATION']
        if (!auth.blank? && auth.match(/Basic /)) then
          (login, password) = Base64.decode64(auth.gsub(/Basic /,'')).split(/:/)
          if User.valid_ldap_credentials?(login, password)
            @current_user = User.find_by_id(login)
          end
        end
      end
    end
    return @current_user
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
    unless current_uid
      store_location
      flash[:notice] = "You must be logged in to access the page you requested"
      redirect_to :controller=>'user_sessions', :action=>'guest_login' and return
    end
  end

  def require_user_or_401
    unless current_user 
      render :status=>401, :text=>"" and return
    end
  end

  def current_group
    @_current_group ||= Group.find(session[:group_id])
  end

  def exceeds_size(object)
    return (object.total_actual_size > APP_CONFIG['max_archive_size'])
  end

  def exceeds_size_version(version)
    return (version.total_actual_size > APP_CONFIG['max_archive_size'])
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def with_fetched_tempfile(*args)
    require 'open-uri'
    require 'fileutils'
    open(*args) do |data|
      tmp_file = Tempfile.new('mrt_http')
      if data.instance_of? File then
        File.copy(data.path, tmp_file.path)
      else
        begin
          while (!(buff = data.read(4096)).nil?)do 
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
  end
  
  # returns the response of the HTTP request for the DUA URI
  def process_dua_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    uri_response = http.request(Net::HTTP::Get.new(uri.request_uri))
    return (uri_response.class == Net::HTTPOK)
  end 

  def params_u(param)
    urlunencode(params[param])
  end

  def paginate_args
    return { 
      :page => (params[:page] || 1), 
      :per_page => 10 }
  end
  
  def stream_response(url, disposition, filename, mediatype, length=nil)
    response.headers["Content-Type"] = mediatype
    response.headers["Content-Disposition"] = "#{disposition}; filename=\"#{filename}\""
    if !length.nil? then 
      response.headers["Content-Length"] = length.to_s
    end
    response.headers['Last-Modified'] = Time.now.httpdate
    self.response_body = Streamer.new(url)
  end
  
  def check_dua(object, redirect_args)
    if params[:blue] then
      # bypass DUA processing for python scripts - indicated by special param
      return
    else
      session[:collection_acceptance] ||= Hash.new(false)
      # check if user already saw DUA and accepted: if so, return
      if session[:collection_acceptance][object.group.id] then
        # clear out acceptance if it does not have session persistence
        if (session[:collection_acceptance][object.group.id] != "session")
          session[:collection_acceptance].delete(object.group.id)
        end
        return
      else
        if object.dua_exists? then
          if process_dua_request(object.dua_uri) then
            # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
            redirect_to({:controller => "dua", :action => "index"}.merge(redirect_args)) and return
          end
        end
      end
    end
  end
  
  def is_ark?(str)
    # return !str.match(/ark:\/[0-9]{5}\/[a-z0-9+]/).nil?
    return !str.match(/ark:\/[0-9a-zA-Z]{1}[0-9]{4}\/[a-z0-9+]/).nil?
  end
end
