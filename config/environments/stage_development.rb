MrtDashboard::Application.configure do
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_view.debug_rjs               = false
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.whiny_nils                        = true
  
  URI_1 = 'http://store.cdlib.org:35121/content/'
end
