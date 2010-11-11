# This file is used by Rack-based servers to start the application.
require 'rack/cache'
require 'lib/rack/munge_headers'

use Rack::ConditionalGet
use Rack::Deflater

use Rack::MungeHeaders,
  :patterns => {
    /^\/(stylesheets|javascripts)/ => {
      "Expires" => Proc.new { (Time.now + 86400).utc.rfc2822 } 
    }
  }

use Rack::Cache,
#  :verbose     => true,
  :metastore   => 'file:' + ::File.expand_path('../tmp/rack-cache/meta', __FILE__),
  :entitystore => 'file:' + ::File.expand_path('../tmp/rack-cache/body', __FILE__)

require ::File.expand_path('../config/environment',  __FILE__)
run MrtDashboard::Application
