require 'rails_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'

# ------------------------------------------------------------
# Capybara etc.

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(args: %w[incognito no-sandbox disable-gpu])
  )
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

Capybara.server = :puma

# ------------------------------------------------------------
# Capybara helpers

def log_in_with(user_id, password)
  visit login_path
  fill_in "login", :with => user_id
  fill_in "password", :with => password
  click_button "Login"
end

def log_out!
  # faster than unless page.has_content?, see https://blog.codeship.com/faster-rails-tests/
  # return if page.has_no_content?('Logout')
  return unless page.text.include?('Logout')

  logout_link = find_link('Logout')
  logout_link.click if logout_link
end
