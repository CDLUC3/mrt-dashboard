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

  def require_group
    redirect_to(CollectionHome) and return false if params[:group].nil?
    begin
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
    #get version of specific object
    q = Q.new("?vers dc:identifier \"#{params[:version]}\"^^<http://www.w3.org/2001/XMLSchema#string> .
                ?vers rdf:type version:Version .
                ?vers version:inObject ?obj .
                ?obj rdf:type object:Object .
                ?obj object:isStoredObjectFor ?meta .
                ?obj dc:identifier \"#{params[:object]}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?vers")

    res = store().select(q)

    #if @results.length != 1 then

    @version = UriInfo.new(res[0]['vers'])
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

end
