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

MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => %w{erik.hetzner@ucop.edu scott.fisher@ucop.edu}
