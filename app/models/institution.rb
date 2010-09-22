# To change this template, choose Tools | Templates
# and open the template in the editor.

class Institution

  LDAP = InstitutionLdap::Server.
    new({ :host            => LDAP_HOST,
          :port            => LDAP_PORT,
          :base            => LDAP_INST_BASE,
          :admin_user      => LDAP_ADMIN_USER,
          :admin_password  => LDAP_ADMIN_PASSWORD,
          :minter          => LDAP_ARK_MINTER_URL})

  #list institution names
  def self.list
    LDAP.institutions
  end
end
