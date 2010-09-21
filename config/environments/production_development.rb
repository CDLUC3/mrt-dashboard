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

  LDAP_USER = UserLdap::Server.new(
       {:host             => "dp01.cdlib.org",
         :port            => 1636,
         :base            => 'ou=People,ou=uc3,dc=cdlib,dc=org',
         :admin_user      => 'Directory Manager',
         :admin_password  => 'XXXXXXXX',
         :minter          => 'http://noid.cdlib.org/nd/noidu_p9'}
    )

  LDAP_GROUP = GroupLdap::Server.new(
       {:host             => "dp01.cdlib.org",
         :port            => 1636,
         :base            => 'ou=mrt-groups,ou=uc3,dc=cdlib,dc=org',
         :admin_user      => 'Directory Manager',
         :admin_password  => 'XXXXXXXX',
         :minter          => 'http://noid.cdlib.org/nd/noidu_p9'}
    )

  INGEST_SERVICE = 'http://.cdlib.org:33121/poster/submit/'

  SPARQL_ENDPOINT = "http://dp01.cdlib.org:8080/sparql/"

  RDF_ARK_URI = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI = "http://uc3.cdlib.org/collection/"

  STORE_URI = "http://badger.cdlib.org:35121/content/10/"

end
