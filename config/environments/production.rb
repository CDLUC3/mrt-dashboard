#this is because I couldn't get our patched library to load otherwise for some reason
$:.unshift File.join(Rails.root, 'vendor','gems', 'net-ldap-0.1.1-patched', 'lib')
require 'user_ldap'
require 'group_ldap'
require 'net/ldap'

MrtDashboard::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = false

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # our configuration
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

  INGEST_SERVICE = 'http://badger.cdlib.org:33121/poster/submit/'

  SPARQL_ENDPOINT = "http://badger.cdlib.org:8080/sparql/"

  RDF_ARK_URI = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI = "http://uc3.cdlib.org/collection/"

  STORE_URI = "http://badger.cdlib.org:35121/content/10/"
end
