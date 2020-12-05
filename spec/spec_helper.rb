require 'colorize'
require 'capybara/webmock'

# ------------------------------------------------------------
# SimpleCov

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.minimum_coverage 100
  SimpleCov.start do
    add_filter '/vendor'
  end
  SimpleCov.start 'rails'
end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  ENV['SSM_SKIP_RESOLUTION'] = 'Y'
  config.color = true
  config.tty = true
  config.formatter = :documentation
  # config.raise_errors_for_deprecations! # TODO: enable this
  config.mock_with :rspec

  if (profile_args_str = ENV['PROFILE'])
    require 'support/profiler'
    # rubocop:disable Security/Eval
    profile_args = eval(profile_args_str)
    # rubocop:enable Security/Eval
    format = profile_args[:format]
    reporter = Profiler.new(format)
    config.reporter.register_listener(reporter, :start, :stop, :dump_summary, :example_started, :example_finished)
  end

  # Enable Capybara webmocks if we are testing a feature
  config.before(:each) do |example|
    if example.metadata[:type] == :feature
      Capybara::Webmock.start
      # Allow Capybara to make localhost requests and also contact the
      # google api chromedriver store
      # WebMock.allow_net_connect!(net_http_connect_on_start: true)
      # WebMock.disable_net_connect!(allow: '*')
      # WebMock.disable_net_connect!(
      #   allow_localhost: true,
      #   allow: %w[chromedriver.storage.googleapis.com]
      # )
    end
  end
  config.after(:suite) do
    Capybara::Webmock.stop
  end
end

require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end
