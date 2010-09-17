#this is because I couldn't get our patched library to load otherwise for some reason
$:.unshift File.join(Rails.root, 'vendor','gems', 'net-ldap-0.1.1-patched', 'lib')
require 'user_ldap'
require 'group_ldap'
require 'net/ldap'

MrtDashboard::Application.configure do
  config.cache_classes = false
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.serve_static_assets = false
  config.i18n.fallbacks = true

  # our configuration
  LDAP_USER = UserLdap::Server.
    new({ :host           => "dp01.cdlib.org",
          :port           => 1636,
          :base           => 'ou=People,ou=uc3,dc=cdlib,dc=org',
          :admin_user     => 'Directory Manager',
          :admin_password => 'XXXXXXXX',
          :minter         => 'http://noid.cdlib.org/nd/noidu_p9' })

  LDAP_GROUP = GroupLdap::Server.
    new({ :host           => "dp01.cdlib.org",
          :port           => 1636,
          :base           => 'ou=mrt-groups,ou=uc3,dc=cdlib,dc=org',
          :admin_user     => 'Directory Manager',
          :admin_password => 'XXXXXXXX',
          :minter         => 'http://noid.cdlib.org/nd/noidu_p9' })

  INGEST_SERVICE     = 'http://uc3.cdlib.org:33121/poster/submit/'
  SPARQL_ENDPOINT    = "http://dp01.cdlib.org:8080/sparql/"
  RDF_ARK_URI        = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI = "http://uc3.cdlib.org/collection/"
end
