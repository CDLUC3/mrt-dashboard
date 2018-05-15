# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

# ------------------------------------------------------------
# Vanilla RSpec

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  # config.raise_errors_for_deprecations!  # TODO: uncomment this
  config.mock_with :rspec

  config.before(:each) do |_example| # double() and allow() are only available in example context
    ldap = double(Net::LDAP)
    allow(Net::LDAP).to receive(:new).and_return(ldap)
  end
end

# ------------------------------------------------------------
# Capybara

require 'capybara/rspec'
require 'capybara/dsl'

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[incognito no-sandbox disable-gpu'])
  )
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

# ------------------------------------------------------------
# RSpec/Rails

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before(:each) do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end

end
