class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:login, :login_post]
  before_filter :require_user,    :only => :logout

  layout "home", :except => ['logout']
  
  def login
    @user_session = UserSession.new
  end
  
  def login_post
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save then
      flash[:notice] = "Login successful!"
      redirect_back_or_default "/"
    else
      render :action => :login
    end
  end
  
  def logout
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default '/'
  end
end
