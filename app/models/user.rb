require 'net/ldap'

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.validate_password_field = false
  end
  
  protected
  def valid_ldap_credentials?(password)
    ldap = Net::LDAP.new
    ldap.host = 'p-irc-dc01.ad.ucop.edu'
    ldap.port = 3268
    ldap.auth("CN=#{self.login},OU=Users,OU=CDL,DC=AD,DC=UCOP,DC=EDU", password)
    
    if !ldap.bind then
      return false
    else 
      res = ldap.search(:base   => "OU=Users,OU=CDL,DC=AD,DC=UCOP,DC=EDU", 
                        :filter => Net::LDAP::Filter.eq("CN", self.login))
      if res.size > 0 then
        first_res = res[0]
        if !first_res[:title].nil? and first_res[:title].size > 0 then
          self.title = first_res[:title][0] 
          self.save
        end
      end
      return true
    end
  end
  
  def self.find_or_create_user(login)
    User.find_or_create_by_login(login)
  end
end
