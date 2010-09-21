require 'user_ldap'
require 'group_ldap'
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

  config.active_support.deprecation        = :log

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  LDAP_ADMIN_PASSWORD = "ahz6ap2I"
  LDAP_ADMIN_USER     = "Directory Manager"
  LDAP_GROUP_BASE     = "ou=mrt-groups,ou=uc3,dc=cdlib,dc=org"
  LDAP_HOST           = "badger.cdlib.org"
  LDAP_PORT           = 1636
  LDAP_USER_BASE      = "ou=People,ou=uc3,dc=cdlib,dc=org"
  LDAP_ARK_MINTER_URL = "http://noid.cdlib.org/nd/noidu_p9"

  INGEST_SERVICE      = 'http://badger.cdlib.org:33121/poster/submit/'
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
  SPARQL_ENDPOINT     = "http://badger.cdlib.org:8080/sparql/"
end
