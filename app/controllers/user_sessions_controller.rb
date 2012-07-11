class UserSessionsController < ApplicationController
  before_filter :require_user,    :only => [:logout]
  
  def login
    session[:expiry_time] = Time.now
#    reset_session
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
    reset_session
    flash[:notice] = "You are now logged out"
    redirect_back_or_default '/'
  end
  
  def guest_login
    debugger
    if User.valid_ldap_credentials?(User::GUEST_USER[:guest_user], User::GUEST_USER[:guest_password]) then
      flash[:notice] = "Login was successful"
      session[:uid] = User::GUEST_USER[:guest_user]
      if !session[:return_to].nil? then
        redirect_to session[:return_to] 
      else
        redirect_back_or_default "/home/choose_collection"
      end
    else
      flash[:notice] = "Login unsuccessful"
      render :action => :login
    end
  end
end
