# monkeypatch, see http://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
class Rack::Response
  def close
    @body.close if @body.respond_to?(:close)
  end
end

class ApplicationController < ActionController::Base
  helper_method :available_groups, :current_user, :current_uid, :current_user_displayname, :current_permissions

  class Streamer
    def initialize(url)
      @url = url
    end
    
    def each 
      HTTPClient.new.get_content(@url) { |chunk|
        yield chunk
      }
    end
  end
  
  class ErrorUnavailable < StandardError; end
  rescue_from ErrorUnavailable, :with => :render_unavailable

  protect_from_forgery
  layout 'application'

  def urlencode(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def urlunencode(item)
    URI.unescape(item)
  end

  def render_unavailable
    render :file => "#{Rails.root}/public/unavailable.html", :status => 500
  end

  helper :all
  
  def current_permissions
    session[:permissions] ||= (current_group.permission(current_uid) || [])
  end
  
  def require_permissions(which, redirect=nil)
    if (!current_permissions.include?(which)) then
      flash[:error] = "You do not have #{which} permissions."
      redirect ||= {
        :action => 'index',
        :group => flexi_group_id,
        :object =>params[:object]  }
      redirect_to(redirect) and return false
    end
  end

  # Return the groups which the user may be a member of
  def available_groups
    if !session[:available_groups] then
      # store the groups in the session as an array of hashes
      groups = current_user.groups.sort_by{|g| g.description.downcase } || []
      session[:available_groups] = groups.map do |group|
        { :id => group.id, 
          :description => group.description,
          :permissions => group.permission(current_user.login) }
      end
    end
    return session[:available_groups]
  end

  private

  #lets the group get itself from the params, but if not, from the session
  def flexi_group_id
    params[:group] or session[:group_id]
  end

  def current_user
    if !defined?(@_current_user) then
      if !session[:uid].nil? then
        # normal form login
        @_current_user = User.find_by_id(session[:uid])
      else
        # http basic auth
        auth = request.headers['HTTP_AUTHORIZATION']
        if (!auth.blank? && auth.match(/Basic /)) then
          (login, password) = Base64.decode64(auth.gsub(/Basic /,'')).split(/:/)
          if User.valid_ldap_credentials?(login, password)
            @_current_user = User.find_by_id(login)
          end
        end
      end
    end
    return @_current_user
  end

  # either return the uid from the session OR get the user id from
  # basic auth. Will not hit LDAP unless using basic auth
  def current_uid
    session[:uid] || current_user.id
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
      # finish encoding the ark: if it wasn't already (apache only encodes slashes)
      session[:return_to].sub!(/ark:/) {|a| urlencode(a) }  
      # redirect_to login_url
      redirect_to :controller=>'user_sessions', :action=>'guest_login' and return
    end
  end

  def require_user_or_401
    unless current_user 
      render :status=>401, :text=>"" and return
    end
  end

  def require_download_permissions
    require_permissions('download')
  end

  def current_group
    @_current_group ||= Group.find(session[:group_id])
  end

  #require a group if user logged in
  #but hackish thing to get group from session instead of params if help files didn't pass it along
  # 3.30.12 mstrong added logic to determine if :group is an object or collection
  def require_group
    # parms{:group] that do not contain an ark id are a collection; all objects contain an ark.
    if !params[:group].nil? then
      if  (params[:group].start_with? "ark") then
        # check for collection existance.  if a collection exists, it an object otherwise it's a collection    
        # unencode the ark for the db lookup
        params[:group] = urlunencode(params[:group])
        @collection = MrtObject.joins(:mrt_collections).
          where("mrt_objects.primary_id = ?", params[:group]).
          map {|c| c.mrt_collections.first }.
          first
        if !@collection.nil? then
          params[:object] = params[:group] 
          params[:group] = @collection.ark 
        end 
      end
    else
      # obtain the group if its not yet been set
      if params[:group].nil? && !params[:object].nil? then
        params[:object] =  urlunencode(params[:object])
        params[:group]= MrtObject.joins(:mrt_collections).
          where("mrt_objects.primary_id = ?", params[:object]).
          map {|c| c.mrt_collections.first }.
          first.ark
      end
    end
    
    raise ErrorUnavailable if flexi_group_id.nil?
    begin
      @group = Group.find(flexi_group_id)
      store_group(@group)
      params[:group] = @group.id
    rescue Exception => ex
      raise ErrorUnavailable
    end
    raise ErrorUnavailable if current_permissions.length < 1
    # initialize the DUA acceptance to false - once the user accepts for a collection, it will be set to true.  
    # Resets at logout
    if session[:collection_acceptance].nil? then 
      session[:collection_acceptance] = Hash.new(false)
    end
  end

  #require write access to this group
  def require_write
    raise ErrorUnavailable if !current_permissions.include?('write')
  end

  def require_mrt_object
    if params[:object].nil? then    
      redirect_to({:controller => 'collection', :action => 'index', :group => flexi_group_id}) and return false
    else
      @object = MrtObject.find_by_primary_id(params[:object])
    end
  end
  
  def require_mrt_version
    if params[:version].nil? then
      redirect_to(:controller => :object,
                  :action => 'index', 
                  :group => flexi_group_id,
                  :object => params[:object]) and return false
    else
      require_mrt_object() if @object.nil?
      @version = @object.versions[params[:version].to_i - 1]
    end
  end

  def exceeds_size
    return (@object.total_actual_size > MAX_ARCHIVE_SIZE)
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end

  def store_object
    session[:object] = request.params[:object]
  end
  
  def store_version
    session[:version] = request.params[:version]
  end
  
  def store_group(group)
    session[:group_id] = group.id
    session[:group_ark] = group.ark_id
    session[:group_description] = group.description
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def esc(i)
    URI.escape(i, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def my_cache(key, expires_in = 600)
    Mrt::Cache.cache(key, expires_in) do
      yield()
    end
  end

  def fetch_to_tempfile(*args)
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
         ensure
           tmp_file.close
         end
      end
      return tmp_file
    end  
  end
 
  def collection_ark
    @collection ||= MrtObject.find_by_primary_id(params[:object]).member_of.first
  end 
    
  # parse the component (object, file, or version) uri to construct
  # the DUA URI
  def construct_dua_uri(rx, component_uri)
     md = rx.match(component_uri.to_s)
     dua_filename = "#{md[1]}/" + urlencode(collection_ark)  + "/0/" + urlencode(APP_CONFIG['mrt_dua_file']) 
     dua_file_uri = dua_filename
     Rails.logger.debug("DUA File URI: " + dua_file_uri)
     return dua_file_uri
  end
        
  # returns the response of the HTTP request for the DUA URI
  def process_dua_request(dua_file_uri)
     uri = URI.parse(dua_file_uri)
     http = Net::HTTP.new(uri.host, uri.port)
     uri_response = http.request(Net::HTTP::Get.new(uri.request_uri))
     return uri_response
  end 
end
