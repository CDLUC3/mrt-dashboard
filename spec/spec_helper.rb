require 'colorize'

# ------------------------------------------------------------
# SimpleCov

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.minimum_coverage 100
  SimpleCov.start 'rails'
end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  # config.raise_errors_for_deprecations! # TODO: enable this
  config.mock_with :rspec
end

require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end
