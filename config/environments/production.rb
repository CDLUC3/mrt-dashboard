MrtDashboard::Application.configure do
  config.cache_classes = false
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.serve_static_assets = false
  config.i18n.fallbacks = true

  LDAP_ADMIN_PASSWORD = "XXXXXXXX"
  LDAP_ADMIN_USER     = "cn=Directory Manager"
  LDAP_GROUP_BASE     = "ou=mrt-groups,ou=uc3,dc=cdlib,dc=org"
  LDAP_HOST           = "dp01.cdlib.org"
  LDAP_PORT           = 1636
  LDAP_USER_BASE      = "ou=People,ou=uc3,dc=cdlib,dc=org"
  LDAP_ARK_MINTER_URL = "http://noid.cdlib.org/nd/noidu_p9"

  INGEST_SERVICE      = 'http://uc3.cdlib.org:33121/poster/submit/'
  SPARQL_ENDPOINT     = "http://dp01.cdlib.org:8080/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
end

MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => %w{erik.hetzner@ucop.edu scott.fisher@ucop.edu}
