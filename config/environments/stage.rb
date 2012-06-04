MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_assets               = true
  
  INGEST_SERVICE      = 'http://dp01.cdlib.org:33121/poster/submit/'
  MINT_SERVICE      = 'http://dp01.cdlib.org:33121/ingest/request-identifier'
  N2T_URI             = "http://n2t.net/"
  SPARQL_ENDPOINT     = "http://dp01.cdlib.org:38082/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => ["erik.hetzner@ucop.edu",
                            "marisa.strong@ucop.edu",
                            "mark.reyes@ucop.edu",
                            "perry.willett@ucop.edu",
                            "scott.fisher@ucop.edu"]
