Rails.application.configure do

  config.action_controller.perform_caching   = true
  config.cache_classes                       = false

  # config.autoload_paths                     += %W[#{config.root}/lib]
  config.consider_all_requests_local         = true
  config.active_support.deprecation          = :log

  config.action_mailer.raise_delivery_errors = false
  # config.action_view.debug_rjs               = true
  config.whiny_nils                          = true

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.log_tags = %i[uuid remote_ip]

  config.eager_load = true
end
