require 'net/ldap'

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.validate_password_field = false
  end
  
  protected
  def valid_ldap_credentials?(password)
    ad_ldap = Net::LDAP.new
    ad_ldap.host = 'p-irc-dc01.ad.ucop.edu'
    ad_ldap.port = 3268
    ad_ldap.auth("CN=#{self.login},OU=Users,OU=CDL,DC=AD,DC=UCOP,DC=EDU", password)
    cdlib_ldap = Net::LDAP.new
    cdlib_ldap.host = 'gales.cdlib.org'
    cdlib_ldap.port = 389
    cdlib_ldap.auth("uid=#{self.login},ou=people,dc=cdlib,dc=org", password)

    res = if cdlib_ldap.bind then
            cdlib_ldap.search(:base   => "ou=people,dc=cdlib,dc=org", 
                              :filter => Net::LDAP::Filter.eq("uid", self.login))
          elsif ad_ldap.bind then
            ad_ldap.search(:base   => "OU=Users,OU=CDL,DC=AD,DC=UCOP,DC=EDU", 
                           :filter => Net::LDAP::Filter.eq("CN", self.login))
          end
    if !res then
      return false
    else
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
