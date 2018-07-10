require 'active_record/errors'
MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths += %W[#{config.root}/lib]
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.i18n.fallbacks = true
  config.serve_static_assets = true

  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :scss

  config.eager_load = true
end

require 'exception_notification'
Rails.application.config.middleware.use(
  ExceptionNotification::Rack,
  email:
    {
      email_prefix: '[Merritt UI] ',
      sender_address: "\"notifier\" <no-reply@#{Socket.gethostname}>",
      exception_recipients: ['marisa.strong@ucop.edu',
                             'mark.reyes@ucop.edu',
                             'david.moles@ucop.edu',
                             'perry.willett@ucop.edu']
    }
)
