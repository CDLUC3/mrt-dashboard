require 'active_record/errors'
MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_assets               = true
  config.active_support.deprecation        = :log

  INGEST_SERVICE      = 'http://uc3-web-stg.cdlib.org:33121/poster/submit/'
  INGEST_SERVICE_UPDATE   = 'http://uc3-web-stg.cdlib.org:33121/poster/update/'
  MERRITT_SERVER      = 'http://merritt-stage.cdlib.org'
  MINT_SERVICE        = 'http://uc3-web-stg.cdlib.org:33121/ingest/request-identifier'
  N2T_URI             = "http://n2t-wf.cdlib.org/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
  CONTAINER_URL       = 'http://merritt-stage.cdlib.org/container/'

  MAX_ARCHIVE_SIZE    = 4294967295   #maximum byte size threshhold for download of object/versions without compression
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => ["marisa.strong@ucop.edu",
                            "shirin.faenza@ucop.edu",
                            "mark.reyes@ucop.edu",
                            "perry.willett@ucop.edu",
                            "scott.fisher@ucop.edu"]
