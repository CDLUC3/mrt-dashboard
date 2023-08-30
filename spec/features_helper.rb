# frozen_string_literal: true

require 'rails_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'
require 'support/downloads'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    # WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.allow_net_connect!(net_http_connect_on_start: true)
  end
  config.after(:each) do
    Downloads.clear!
  end
  config.after(:all) do
    Downloads.remove_directory!
  end
end

# ------------------------------------------------------------
# Capybara etc.

Capybara.default_driver = :rack_test

# This is a customisation of the default :selenium_chrome_headless config in:
# https://github.com/teamcapybara/capybara/blob/master/lib/capybara.rb
#
# This adds the --no-sandbox flag to fix TravisCI as described here:
# https://docs.travis-ci.com/user/chrome#sandboxing
Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|

  config.before(:each, type: :feature, js: false) do
    Capybara.use_default_driver
  end

  config.before(:each, type: :feature, js: true) do
    Webdrivers.cache_time = 0
    Capybara.current_driver = :selenium_chrome_headless
    # the following is needed for github actions
    Webdrivers::Chromedriver.required_version = '118.0.5981.0'
    # Toggle the following when needed during testing
    # Capybara.current_driver = :selenium_chrome
  end

end

Capybara.configure do |config|
  config.default_max_wait_time = 5 # seconds
  config.server                = :webrick
  config.raise_server_errors   = true
end

# ------------------------------------------------------------
# Capybara helpers

def wait_for_ajax!
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.evaluate_script("(typeof Ajax === 'undefined') ? 0 : Ajax.activeRequestCount").zero?
  end
end

def log_in_with(user_id, password)
  visit login_path
  fill_in 'login', with: user_id
  fill_in 'password', with: password
  click_button 'Login'
  wait_for_ajax!
end

def log_out!
  # faster than unless page.has_content?, see https://blog.codeship.com/faster-rails-tests/
  # return if page.has_no_content?('Logout')
  return unless page.text.include?('Logout')

  click_link('Logout', match: :first)
end
