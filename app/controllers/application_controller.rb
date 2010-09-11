class ApplicationController < ActionController::Base

  Q = Mrt::Sparql::Q
  protect_from_forgery
  layout 'application'

  CollectionHome = {:controller => 'home', :action => 'choose_collection'}
  ObjectList = {:controller => 'collection', :action => 'index'}

  def store
    return Mrt::Sparql::Store.new(SPARQL_ENDPOINT)
  end

  helper :all
  helper_method :current_user_session, :current_user
  
  private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  
  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access the page you requested"
      redirect_to login_url
      return false
    end
  end

  #require a group, but hackish thing to get group from session instead of params for help
  def require_group
    redirect_to(CollectionHome) and return false if params[:group].nil? and session[:group].nil?
    begin
      session[:group] = params[:group] if !params[:group].nil?
      params[:group] = session[:group] if params[:group].nil?
      @group = Group.find(params[:group])
    rescue Exception => ex
      redirect_to(CollectionHome)
      return false
    end
    begin
      @permissions = @group.permission(current_user.login)
    rescue Exception => ex
      redirect_to(CollectionHome)
      return false
    end
    redirect_to(CollectionHome) and return false if @permissions.length < 1
    @groups = current_user.groups.sort{|x, y| x.description.downcase <=> y.description.downcase}
  end

  def require_object
    redirect_to(ObjectList.merge({:group => params[:group]})) and return false if params[:object].nil?
    begin
      @object = UriInfo.new("#{RDF_ARK_URI}#{params[:object]}")
    rescue Exception => ex
      redirect_to(ObjectList.merge({:group => params[:group]})) and return false
    end
  end

  def require_version
    redirect_to(:controller => :object, :action => 'index', :group => :params[:group], :object => params[:object]) and return false if params[:version].nil?
    #get version of specific object
    q = Q.new("?vers dc:identifier \"#{params[:version]}\"^^<http://www.w3.org/2001/XMLSchema#string> .
                ?vers rdf:type version:Version .
                ?vers version:inObject ?obj .
                ?obj rdf:type object:Object .
                ?obj object:isStoredObjectFor ?meta .
                ?obj dc:identifier \"#{params[:object]}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?vers")

    res = store().select(q)

    redirect_to(:controller => :object, :action => 'index', :group => :params[:group], :object => params[:object]) and return false if res.length != 1

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

end
