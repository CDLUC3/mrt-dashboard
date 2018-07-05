require 'active_record/errors'
MrtDashboard::Application.configure do
  config.action_controller.perform_caching = true
  config.autoload_paths                   += %W(#{config.root}/lib)
  config.cache_classes                     = true
  config.consider_all_requests_local       = false
  config.i18n.fallbacks                    = true
  config.serve_static_files		   = true

  config.active_support.deprecation        = :log

  config.eager_load                          = false
end

require 'exception_notifier'
MrtDashboard::Application.config.middleware.use ExceptionNotification::Rack,
:email => {
    :deliver_with => :deliver, # Rails >= 4.2.1 do not need this option since it defaults to :deliver_now
    :email_prefix => "[Merritt UI] ",
    :sender_address => "\"notifier\" <no-reply@#{Socket.gethostname}>",
    :exception_recipients => ["marisa.strong@ucop.edu",
                            "mark.reyes@ucop.edu",
                            "david.moles@ucop.edu",
                            "perry.willett@ucop.edu"]
  }
