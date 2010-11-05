MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_assets               = false
  
  ActionController::Base.cache_store = :file_store, "tmp/cache"

  INGEST_SERVICE      = 'http://uc3.cdlib.org:33121/poster/submit/'
  SPARQL_ENDPOINT     = "http://dp01.cdlib.org:8082/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => %w{erik.hetzner@ucop.edu scott.fisher@ucop.edu}
