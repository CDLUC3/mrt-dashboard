class ApplicationController < ActionController::Base

  class ErrorUnavailable < StandardError; end
  rescue_from ErrorUnavailable, :with => :render_unavailable

  Q = Mrt::Sparql::Q
  protect_from_forgery
  layout 'application'

  CollectionHome = {:controller => 'home', :action => 'choose_collection'}
  ObjectList = {:controller => 'collection', :action => 'index'}


  def urlencode(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end


  def render_unavailable
    render :file => "#{Rails.root}/public/unavailable.html", :status => 500
  end

  def store
    return Mrt::Sparql::Store.new(SPARQL_ENDPOINT)
  end

  helper :all
  helper_method :current_user
  
  private

  #lets the group get itself from the params, but if not, from the session
  def flexi_group_id
    params[:group] or session[:group]
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = session[:uid] && User.find_by_id(session[:uid])
  end
  
  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access the page you requested"
      redirect_to login_url
      return false
    end
  end

  # tries to get the group for help files, but otherwise skips
  def group_optional
    grp = flexi_group_id
    if grp.nil? then
      @group = nil
    else
      @group = Group.find(flexi_group_id)
      require_group
    end
  end
  
  #require a group if user logged in
  #but hackish thing to get group from session instead of params if help files didn't pass it along
  def require_group
    raise ErrorUnavailable if flexi_group_id.nil?
    begin
      @group = Group.find(flexi_group_id)
      session[:group] = @group.id
      params[:group] = @group.id
    rescue Exception => ex
      raise ErrorUnavailable
    end
    begin
      @permissions = @group.permission(current_user.login)
    rescue Exception => ex
      raise ErrorUnavailable
    end
    raise ErrorUnavailable if @permissions.length < 1
    @groups = current_user.groups.sort{|x, y| x.description.downcase <=> y.description.downcase}
    @group_ids = @groups.map{|grp| grp.id}
    raise ErrorUnavailable if !@group_ids.include?(flexi_group_id)
  end

  #require write access to this group
  def require_write
    raise ErrorUnavailable if !@permissions.include?('write')
  end

  def require_object
    redirect_to(ObjectList.merge({:group => flexi_group_id})) and return false if params[:object].nil?
    begin
      @object = UriInfo.new("#{RDF_ARK_URI}#{params[:object]}")
    rescue Exception => ex
      redirect_to(ObjectList.merge({:group => flexi_group_id})) and return false
    end
  end

  def require_mrt_object
    redirect_to(ObjectList.merge({:group => flexi_group_id})) and return false if params[:object].nil?
    begin
      @object = MrtObject.find_by_identifier(params[:object])
    rescue Exception => ex
      redirect_to(ObjectList.merge({:group => flexi_group_id})) and return false
    end
  end
  
  def require_mrt_version
    redirect_to(:controller => :object,
                :action => 'index', 
                :group => flexi_group_id,
                :object => params[:object]) and return false if params[:version].nil?
    require_mrt_object() if @object.nil?
    @version = @object.versions[params[:version].to_i - 1]
  end

  def require_version
    redirect_to(:controller => :object, :action => 'index', :group => flexi_group_id, :object => params[:object]) and return false if params[:version].nil?
    #get version of specific object
    q = Q.new("?vers dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> .
                ?vers rdf:type version:Version .
                ?vers version:inObject ?obj .
                ?obj rdf:type object:Object .
                ?obj object:isStoredObjectFor ?meta .
                ?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?vers")

    res = store().select(q)

    redirect_to(:controller => :object, :action => 'index', :group => flexi_group_id, :object => params[:object]) and return false if res.length != 1

    @version = UriInfo.new(res[0]['vers'])
  end

  def file_state_uri(id, version, fn)
    "#{FILE_STATE_URI}#{esc(id)}/#{esc(version)}/#{esc(fn)}"
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to '/'
      return false
    end
  end
  
  def store_location
    session[:return_to] = request.request_uri
  end
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def esc(i)
    URI.escape(i, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def no_inject(str)
    str.gsub('"', '\\"')
  end

  #this chooses the first group if one isn't set since Tracy's help layout
  #requires a group, even though it might not have been chosen.  It's wacky
  #but a way to solve the shady layout.
  def first_group_if_unset
    grps = current_user.groups
    if grps.length < 1 then
      redirect_to "/home/logout" and return false
    end
    session[:group] = grps[0].id
    params[:group] = grps[0].id
  end

  def my_cache(key, expires_in = 600)
    Mrt::Cache.cache(key, expires_in) do
      yield()
    end
  end

  def fetch_to_tempfile(*args)
    require 'open-uri'
    require 'ftools'
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
end
