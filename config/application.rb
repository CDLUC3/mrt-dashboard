require_relative 'boot'

require 'rails/all'
require 'uc3-ssm'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MrtDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    def config.database_configuration
      # The entire config must be returned, but only the Rails.env will be processed
      Uc3Ssm::ConfigResolver.new.resolve_file_values({ name: 'config/database.yml' })
    end

  end
end
