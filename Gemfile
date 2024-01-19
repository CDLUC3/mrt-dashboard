source 'http://rubygems.org'

gem 'activeresource'
gem 'json'
gem 'multi_json'
gem 'mysql2'
gem 'rails', '~> 6.0'

gem 'aws-sdk-ec2'
gem 'aws-sdk-ssm'
gem 'bootsnap'
gem 'builder'
gem 'capistrano', '3.14.1'
gem 'capistrano-rails'

gem 'exception_notification'
gem 'httpclient'
gem 'irb'
gem 'jquery-rails'
gem 'lograge'
gem 'logstash-event'
# New lib does not use One Time Server
gem 'net-ldap'
gem 'net-smtp'
gem 'nokogiri'
gem 'orchard'
gem 'puma'
gem 'rack-cache'
gem 'rest-client'
gem 'sprockets'
gem 'thin'
gem 'uc3-ssm', '0.3.10', git: 'https://github.com/CDLUC3/uc3-ssm', branch: 'main'
gem 'uglifier'
gem 'unicode'
gem 'uuidtools'
gem 'will_paginate'
gem 'psych', '5.0.0'

group :development do
  gem 'web-console'
end

group :development, :test, :docker do
  gem 'byebug'
  gem 'colorize'
  gem 'debase', '0.2.5.beta2'
  gem 'launchy'
  gem 'listen'
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote', require: 'pry-remote'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'ruby-debug-ide'
  gem 'ruby-prof'
end

group :test do
  gem 'capybara'
  gem 'capybara-webmock'
  gem 'database_cleaner'
  gem 'diffy'
  gem 'equivalent-xml'
  # rails 4.2, do not unpeg the following line
  gem 'factory_bot_rails'
  gem 'simplecov'
  gem 'simplecov-console'

  # Run Selenium tests more easily with automatic installation and updates
  # for all supported webdrivers.
  gem 'selenium-webdriver', '~> 4.11'
  # gem 'webdrivers'
  gem 'webmock'
end
