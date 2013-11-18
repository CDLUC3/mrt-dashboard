# This file is used by Rack-based servers to start the application.
#require File.expand_path('../lib/rack/munge_headers', __FILE__)

#use Rack::MungeHeaders,
#  :patterns => {
#    /^\/(stylesheets|javascripts|images)/ => {
#      "Expires" => Proc.new { (Time.now + 31536000).utc.rfc2822 } 
#    }
#  }

require ::File.expand_path('../config/environment',  __FILE__)
run MrtDashboard::Application
