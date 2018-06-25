# Load the rails application
require File.expand_path('../application', __FILE__)

Dir[File.dirname(__FILE__) + '/../vendor/*'].each do |path|
  gem_name = File.basename(path.gsub(/-\d+.\d+.\d+$/, ''))
  gem_path = path + '/lib/' + gem_name + '.rb'
  require gem_path if File.exists? gem_path
end

# Initialize the rails application
MrtDashboard::Application.initialize!

require 'webrick/httputils'
Rack::Mime::MIME_TYPES['.xlsm'] = 'application/vnd.ms-excel.sheet.macroEnabled.12'

# TODO: don't assume existence of /dpr2
ENV['TMPDIR'] = Rails.root.join('/dpr2/tmpdir').to_s unless ENV['RAILS_ENV'] == 'test'
