Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = ->(event) do
    { time: event.time, request_id: request.request_id }
  end
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.keep_original_rails_log = true
  if %w[production stage].include?(Rails.env)
    config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/lograge_#{Rails.env}.log"
  else
    config.lograge.logger = ActiveSupport::Logger.new($stdout)
  end
end
