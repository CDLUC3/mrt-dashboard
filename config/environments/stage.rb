require 'active_record/errors'
MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W[#{config.root}/lib]
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_files = true

  # To turn off pipeline, set to false
  config.assets.enabled = false

  # Compress JavaScripts and CSS.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :yui

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  config.active_support.deprecation = :log

end

require 'exception_notification'
Rails.application.config.middleware.use(
  ExceptionNotification::Rack,
  email: {
    email_prefix: '[Merritt UI] ',
    sender_address: "\"notifier\" <no-reply@#{Socket.gethostname}>",
    exception_recipients: ['marisa.strong@ucop.edu',
                           'mark.reyes@ucop.edu',
                           'terrence.brady@ucop.edu',
                           'eric.lopatin@ucop.edu']
  }
)
