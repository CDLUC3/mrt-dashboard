class User < ActiveRecord::Base
  LDAP = UserLdap::Server.
    new({ :host            => LDAP_CONFIG["host"],
          :port            => LDAP_CONFIG["port"],
          :base            => LDAP_CONFIG["user_base"],
          :admin_user      => LDAP_CONFIG["admin_user"],
          :admin_password  => LDAP_CONFIG["admin_password"],
          :minter          => LDAP_CONFIG["ark_minter_url"]})

  acts_as_authentic do |c|
    c.validate_password_field = false
  end

  def self.find_all
    LDAP.find_all
  end
 
  def groups
    grp_ids = Group::LDAP.find_groups_for_user(self.login, User::LDAP)
    grp_ids.map{|id| Group.find(id)}
  end

  #these would be LDAP attributes, not database ones.  maybe they should sync up more.
  def set_attrib(attribute, value)
    LDAP_USER.replace_attribute(self.login, attribute, value)
  end

  #protected
  def valid_ldap_credentials?(password)
    begin
      res = User::LDAP.authenticate(login, password)

    rescue LdapMixin::LdapException => ex
      return false
    end
    return false if res == false

    u = User::LDAP.fetch(login)
    self.title = single_value(u, 'title')
    self.displayname = single_value(u, 'displayname')
    self.lastname = single_value(u, 'sn')
    self.firstname = single_value(u, 'givenname')
    self.email = single_value(u, 'mail')
    self.save
    true
  end

  def self.find_or_create_user(login)
    User.find_or_create_by_login(login)
  end
  
  def single_value(record, field)
    if record[field].nil? or record[field][0].nil? or record[field][0].length < 1 then
      return nil 
    else
      return record[field][0]
    end
  end

end
