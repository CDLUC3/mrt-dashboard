MrtDashboard::Application.configure do

  config.action_controller.perform_caching = true
  config.cache_classes = false

  config.autoload_paths += %W(#{config.root}/lib)
  config.consider_all_requests_local = true
  config.active_support.deprecation = :log

  config.action_mailer.raise_delivery_errors = false
  # config.action_view.debug_rjs               = true
  # config.whiny_nils                          = true

  config.assets.enabled = false
  config.assets.debug = false

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.eager_load = false

  config.log_tags = [:uuid, :remote_ip]
end

# TODO: remove this once we trust the switch to exception_notification works
require 'exception_notification'
Rails.application.config.middleware.use(
  ExceptionNotification::Rack,
  email: {
    email_prefix: '[Merritt UI] ',
    sender_address: "\"notifier\" <no-reply@#{Socket.gethostname}>",
    exception_recipients: ['marisa.strong@ucop.edu',
                           'mark.reyes@ucop.edu',
                           'david.moles@ucop.edu',
                           'perry.willett@ucop.edu']

  }
)
