MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_assets               = true
  
  INGEST_SERVICE      = 'http://uc3.cdlib.org:33121/poster/submit/'
  INGEST_SERVICE_UPDATE   = 'http://uc3.cdlib.org:33121/poster/submit/'
  MERRITT_SERVER      = 'http://merritt.cdlib.org'
  MINT_SERVICE        = 'http://uc3.cdlib.org:33121/ingest/request-identifier'
  N2T_URI             = "http://n2t.net/"
  SPARQL_ENDPOINT     = "http://inventory.cdlib.org:8082/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
  STORAGE_SERVICE     = 'http://uc3a-dev.cdlib.org:35121/async/910/'
  CONTAINER_URL       = 'http://uc3a-dev.cdlib.org:35121/container/'
  
  MAX_ARCHIVE_SIZE    = 4294967295
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => ["marisa.strong@ucop.edu",
                            "mark.reyes@ucop.edu",
                            "perry.willett@ucop.edu",
                            "scott.fisher@ucop.edu"]
