# To change this template, choose Tools | Templates
# and open the template in the editor.

class Institution

  LDAP = InstitutionLdap::Server.
    new({ :host            => LDAP_CONFIG['host'],
          :port            => LDAP_CONFIG['port'],
          :base            => LDAP_CONFIG['inst_base'],
          :admin_user      => LDAP_CONFIG['admin_user'],
          :admin_password  => LDAP_CONFIG['admin_password'],
          :connect_timeout => LDAP_CONFIG['connect_timeout'],
          :minter          => LDAP_CONFIG['ark_minter_url']})

  def self.find_all
    LDAP.find_all
  end
end
