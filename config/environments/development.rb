MrtDashboard::Application.configure do
  config.action_controller.perform_caching   = false
  config.action_mailer.raise_delivery_errors = false
  config.action_view.debug_rjs               = true
  config.active_support.deprecation          = :log
  config.cache_classes                       = false
  config.consider_all_requests_local         = true
  config.whiny_nils                          = true


  LDAP_ADMIN_PASSWORD = "ahz6ap2I"
  LDAP_ADMIN_USER     = "cn=Directory Manager"
  LDAP_GROUP_BASE     = "ou=mrt-groups,ou=uc3,dc=cdlib,dc=org"
  LDAP_HOST           = "badger.cdlib.org"
  LDAP_PORT           = 1636
  LDAP_USER_BASE      = "ou=People,ou=uc3,dc=cdlib,dc=org"
  LDAP_INST_BASE      = "o=institutions,ou=uc3,dc=cdlib,dc=org"
  LDAP_ARK_MINTER_URL = "http://noid.cdlib.org/nd/noidu_p9"

  INGEST_SERVICE      = 'http://badger.cdlib.org:33121/poster/submit/'
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
  SPARQL_ENDPOINT     = "http://badger.cdlib.org:8082/sparql/"
end
