source 'http://rubygems.org'

gem 'rails', '3.2.12'

gem 'mysql2'
gem "httpclient", "~> 2.2.5"
gem "eco_exception_notification",
    :git => "git://github.com/chrisfinne/eco_exception_notification.git"
gem "net-ldap", :git => "git://github.com/ruby-ldap/ruby-net-ldap.git", :branch => "master"
gem "nokogiri"
gem "rest-client"
gem "unicorn", "4.5.0"
gem "will_paginate"
gem "rack-cache"
gem "unicode"
gem "orchard"
gem "mrt-ingest", "0.0.2"
gem "builder"
gem 'uuidtools'
gem 'thin'
gem 'jquery-rails'

group :test, :development do
 	gem 'debugger'
  gem 'rspec-rails'
  gem 'factory_girl_rails', :require => false
  gem 'launchy'
end

group :test do  
  gem 'selenium-webdriver'
  gem 'sqlite3'
  #gem "capybara-webkit"
  gem 'capybara' 
  gem "database_cleaner", "~> 1.0.1"
end
