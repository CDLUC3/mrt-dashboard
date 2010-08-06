# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
MrtDashboard::Application.initialize!
require 'ostruct'
require 'mrt/kernel'
require 'mrt/sparql'
require 'mrt/mrt'
require 'mrt/http'
#require 'nokogiri'
