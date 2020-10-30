class UserSessionsController < ApplicationController
  before_action :require_user, only: [:logout]

  def login
    reset_session
  end

  def login_post
    handle_login(params[:login], params[:password])
  end

  def logout
    reset_session
    flash[:notice] = 'You are now logged out'
    redirect_back_or_default url_for_with_proto({ controller: 'home', action: 'index' })
  end

  def guest_login
    handle_login(LDAP_CONFIG['guest_user'], LDAP_CONFIG['guest_password'])
  end

  protected

  def handle_login(user_id, password)
    session[:expiry_time] = Time.now
    if User.valid_ldap_credentials?(user_id, password)
      session[:uid] = user_id
      puts("TBTB1111")
      puts(session[:uid])
      puts(url_for_with_proto({ controller: 'home', action: 'choose_collection' }))
      redirect_back_or_default url_for_with_proto({ controller: 'home', action: 'choose_collection' })
    else
      flash[:notice] = 'Login unsuccessful'
      render action: :login
    end
  end

end
