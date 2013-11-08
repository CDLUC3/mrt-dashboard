require 'active_record/errors'
MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_assets               = true

  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor  = :uglifier
  config.assets.css_compressor = :scss
  
  INGEST_SERVICE      = 'http://uc3-web.cdlib.org:33121/poster/submit/'
  INGEST_SERVICE_UPDATE   = 'http://uc3-web.cdlib.org:33121/poster/update/'
  MINT_SERVICE        = 'http://uc3-web.cdlib.org:33121/ingest/request-identifier'
  N2T_URI             = "http://n2t.net/"
  URI_1 = 'http://store.cdlib.org:35121/content/'
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Merritt UI] ",
  :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
  :exception_recipients => ["marisa.strong@ucop.edu",
                            "mark.reyes@ucop.edu",
                            "perry.willett@ucop.edu",
                            "scott.fisher@ucop.edu"]
