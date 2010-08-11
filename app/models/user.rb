class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.validate_password_field = false
  end
 
  def groups
    grps = LDAP_SERVER.groups_for_user(self.login)
    grps.map{|g| Group.find(g)}
  end

  protected
  def valid_ldap_credentials?(password)
    begin
      res = LDAP_SERVER.authenticate(login, password)
    rescue LdapCdl::LdapException => ex
      return false
    end
    return false if res == false

    u = LDAP_SERVER.fetch(login)
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
    return nil if record[field].nil? or record[field][0].nil? or record[field][0].length < 1
    return record[field][0]
  end

end
