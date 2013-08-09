MrtDashboard::Application.configure do
  config.action_controller.perform_caching   = false
  config.action_mailer.raise_delivery_errors = false
  #config.action_view.debug_rjs               = true
  config.active_support.deprecation          = :log
  config.autoload_paths                     += %W(#{config.root}/lib)
  config.cache_classes                       = false
  config.consider_all_requests_local         = true
  config.whiny_nils                          = true

  
  config.assets.enabled = false
  config.assets.debug = false

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.log_tags = [:uuid, :remote_ip]

  INGEST_SERVICE      = 'http://uc3-mrt-wrk1-dev.cdlib.org:33121/poster/submit/'
  INGEST_SERVICE_UPDATE   = 'http://uc3-mrt-wrk1-dev.cdlib.org:33121/poster/update/'
  MINT_SERVICE        = 'http://uc3-mrt-wrk1-dev.cdlib.org:33121/request-identifier'
  N2T_URI             = "http://n2t-wf.cdlib.org/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
  # SPARQL_ENDPOINT     = "http://badger.cdlib.org:8082/sparql/"
  CONTAINER_URL       = 'http://uc3-mrt-store-dev.cdlib.org:35121/container/'

  MAX_ARCHIVE_SIZE    = 2147483648
end
