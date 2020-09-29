source 'http://rubygems.org'

gem 'activeresource'
gem 'multi_json'
gem 'mysql2', '~> 0.4.0' # TODO: update to 0.5 once we're on a Rails that supports it
gem 'rails', '~> 4.2.11'

gem 'aws-sdk-ec2'
gem 'aws-sdk-ssm'
gem 'builder'
gem 'capistrano'
gem 'capistrano-rails'
gem 'exception_notification'
gem 'httpclient'
gem 'jquery-rails'
gem 'mrt-ingest'
gem 'net-ldap'
gem 'nokogiri'
gem 'orchard'
gem 'puma'
gem 'rack-cache'
gem 'rest-client'
gem 'sprockets'
gem 'thin'
gem 'uc3-ssm', git: 'https://github.com/CDLUC3/uc3-ssm', branch: 'main'
gem 'unicode'
gem 'uuidtools'
gem 'will_paginate'

group :development do
  gem 'web-console', '~> 2.0'
end

group :development, :test do
  gem 'byebug'
  gem 'colorize', '~> 0.8'
  gem 'launchy'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote', require: 'pry-remote'
  gem 'rspec-rails', '~> 3.0'
  gem 'rubocop', '0.58.1'
  gem 'ruby-prof', '~> 0.17'
end

group :test do
  gem 'capybara'
  gem 'capybara-webmock'
  # gem 'chromedriver-helper', '~> 2.0'
  gem 'database_cleaner', '~> 1.5'
  gem 'diffy', '~> 3.1'
  gem 'equivalent-xml', '~> 0.6.0'
  gem 'factory_bot_rails', '~> 4.11'
  # gem 'selenium-webdriver', '~> 3.7'
  gem 'simplecov', '~> 0.14'
  gem 'simplecov-console', '~> 0.4'

  # Run Selenium tests more easily with automatic installation and updates
  # for all supported webdrivers.
  gem 'webdrivers', '~> 3.0'

  gem 'webmock', '~> 3.0'
end
