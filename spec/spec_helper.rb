require 'colorize'

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

  if (profile_args_str = ENV.fetch('PROFILE', nil))
    require 'support/profiler'
    # rubocop:disable Security/Eval
    profile_args = eval(profile_args_str)
    # rubocop:enable Security/Eval
    format = profile_args[:format]
    reporter = Profiler.new(format)
    config.reporter.register_listener(reporter, :start, :stop, :dump_summary, :example_started, :example_finished)
  end

end

require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV.fetch('RAILS_ENV', nil))
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end
