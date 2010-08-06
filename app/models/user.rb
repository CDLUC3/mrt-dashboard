require 'net/ldap'

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.validate_password_field = false
  end
  
  protected
  def valid_ldap_credentials?(password)
    ldap = Net::LDAP.new
    ldap.host = LDAP_HOST
    ldap.port = LDAP_PORT
    ldap.encryption(LDAP_ENCRYPTION)
    ldap.auth("uid=#{self.login},#{LDAP_BASE}", password)

    if !ldap.bind then
      return false
    else
      res = ldap.search(:base   => LDAP_BASE,
                        :filter => Net::LDAP::Filter.eq("uid", self.login))
      if !res or res.size == 0 then
        return false
      else
        first_res = res[0]
        if !first_res[:title].nil? and first_res[:title].size > 0 then
          self.title = first_res[:title][0] 
          self.save
        end
        return true
      end
    end
  end
  
  def self.find_or_create_user(login)
    User.find_or_create_by_login(login)
  end
end
