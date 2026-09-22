Rails.application.configure do
  if Rails.env.test?
    # prevent stdout of lograge when testing
    config.lograge.enabled = false
  else
    config.lograge.enabled = true
    config.lograge.custom_options = ->(event) do
      { time: event.time }
    end
    config.lograge.formatter = Lograge::Formatters::Logstash.new
    config.lograge.keep_original_rails_log = true
    if %w[production stage].include?(Rails.env)
      config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/lograge_#{Rails.env}.log"
    else
      config.lograge.logger = ActiveSupport::Logger.new($stdout)
    end
  end
end
