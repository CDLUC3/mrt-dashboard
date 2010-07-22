class UserSession < Authlogic::Session::Base
  find_by_login_method   :find_or_create_user
  verify_password_method :valid_ldap_credentials?
end
