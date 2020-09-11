require 'spec_helper'
require 'support/ark'
require 'support/factory_bot'
require 'support/ldap'

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'database_cleaner'

# Stop Rails enthusiastically blowing away test database
# https://github.com/rails/rails/issues/18982
if ENV['RAILS_ENV'] == 'test'
  class ActiveRecord::Migrator
    class << self
      def any_migrations?
        true
      end
    end
  end
end

ActiveRecord::Migration.maintain_test_schema!

def check_connection_config!
  db_config = ActiveRecord::Base.connection_config
  host = db_config[:host]
  raise("Can't run destructive tests against non-local database #{host || 'nil'}") unless ['localhost', '127.0.0.1'].include?(host)
  msg = "Using database #{db_config[:database]} on host #{host} with username #{db_config[:username]}"
  puts msg.colorize(:yellow)
end

RSpec.configure do |config|

  # allow test DB access from multiple connections
  config.use_transactional_fixtures = false

  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion

    check_connection_config!

    puts 'Clearing test database'.colorize(:yellow)
    DatabaseCleaner.clean
  end

  config.before(:each) do
    Rails.cache.clear
  end

  config.after(:each) do
    begin
      DatabaseCleaner.clean
    rescue StandardError => e
      Rails.logger.error(e.to_s)
    end
  end
end
