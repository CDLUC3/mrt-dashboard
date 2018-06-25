require 'rubygems'

# Set up gems listed in the Gemfile for rails 3.1.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
