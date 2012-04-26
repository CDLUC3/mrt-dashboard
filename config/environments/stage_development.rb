MrtDashboard::Application.configure do
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_view.debug_rjs               = false
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.whiny_nils                        = true
  
  INGEST_SERVICE      = 'http://dp01.cdlib.org:33121/poster/submit/'
  MINT_SERVICE      = 'http://dp01.cdlib.org:33121/request-identifier
  SPARQL_ENDPOINT     = "http://dp01.cdlib.org:38082/sparql/"
  RDF_ARK_URI         = "http://ark.cdlib.org/"
  RDF_COLLECTION_URI  = "http://uc3.cdlib.org/collection/"
end
