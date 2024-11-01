require_relative 'boot'

require 'rails/all'
require 'uc3-ssm'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MrtDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    def config.database_configuration
      # The entire config must be returned, but only the Rails.env will be processed
      Uc3Ssm::ConfigResolver.new.resolve_file_values(file: 'config/database.yml')
    end
  end
end
