MrtDashboard::Application.configure do
  config.cache_classes                       = false
  config.whiny_nils                          = true
  config.consider_all_requests_local         = true
  config.action_view.debug_rjs               = true
  config.action_controller.perform_caching   = false
  config.active_support.deprecation          = :log
  config.action_mailer.raise_delivery_errors = false

  LDAP_ADMIN_PASSWORD = "wah8oLab"
  LDAP_ADMIN_USER     = "cn=Directory Manager"
  LDAP_GROUP_BASE     = "ou=mrt-groups,ou=uc3,dc=cdlib,dc=org"
  LDAP_HOST           = "dp01.cdlib.org"
  LDAP_PORT           = 1636
  LDAP_USER_BASE      = "ou=People,ou=uc3,dc=cdlib,dc=org"
  LDAP_ARK_MINTER_URL = "http://noid.cdlib.org/nd/noidu_p9"

  INGEST_SERVICE      = 'http://uc3.cdlib.org:33121/poster/submit/'
  SPARQL_ENDPOINT     = "http://dp01.cdlib.org:8082/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
end
