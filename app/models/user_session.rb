class UserSession < Authlogic::Session::Base
  find_by_login_method   :find_or_create_user
  verify_password_method :valid_ldap_credentials?
  # Fix for authlogic 2.1.6 problem with rails 3
  include ActiveModel::Conversion
  def persisted?
    false
  end
  # End of fix
end
