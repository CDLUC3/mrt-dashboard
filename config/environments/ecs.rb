require 'active_record/errors'
Rails.application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W[#{config.root}/lib]
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_files = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = false

  config.active_support.deprecation = :log

  # Store uploaded files on the local file system (see config/storage.yml for options). 
  config.active_storage.service = :ecs

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
end
