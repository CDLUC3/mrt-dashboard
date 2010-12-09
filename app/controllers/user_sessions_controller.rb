class UserSessionsController < ApplicationController
  before_filter :require_user,    :only => [:logout]
  
  def login
    reset_session
  end
  
  def login_post
    if User.valid_ldap_credentials?(params[:login], params[:password]) then
      flash[:notice] = "Login was successful"
      session[:uid] = params[:login]
      redirect_back_or_default "/home/choose_collection"
    else
      flash[:notice] = "Login unsuccessful"
      render :action => :login
    end
  end
  
  def logout
    session[:group] = nil
    session[:user] = nil
    reset_session
    flash[:notice] = "You are now logged out"
    redirect_back_or_default '/'
  end
end
