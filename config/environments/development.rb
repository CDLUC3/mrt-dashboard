require 'ldap_cdl'
MrtDashboard::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

 LDAP_SERVER = LdapCdl::Server.new(
       {:host            => "badger.cdlib.org",
         :port            => 1636,
         :people_base     => 'ou=People,ou=uc3,dc=cdlib,dc=org',
         :groups_base     => 'ou=uc3,dc=cdlib,dc=org',
         :admin_user      => 'Directory Manager',
         :admin_password  => 'ahz6ap2I',
         :minter          => 'http://noid.cdlib.org/nd/noidu_g9'}
    )

  LDAP_HOST       = "badger.cdlib.org"
  LDAP_PORT       = 1636
  LDAP_ENCRYPTION = { :method => :simple_tls }
  LDAP_BASE       = "ou=People,ou=uc3,dc=cdlib,dc=org"
  LDAP_ADMIN_USER = "cn=Directory Manager"
  LDAP_ADMIN_PASS = "xxxxxxx"
  SPARQL_ENDPOINT = "http://badger.cdlib.org:8080/sparql/"
end
