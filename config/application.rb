require_relative 'boot'

require 'rails/all'
require 'uc3-ssm'
require 'tempfile'
# require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MrtDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.global_id.app = 'mrt-dashboard'

    def config.database_configuration
      # The entire config must be returned, but only the Rails.env will be processed
      Uc3Ssm::ConfigResolver.new(def_value: 'NOT_APPLICABLE').resolve_file_values(file: 'config/database.yml')
    end

    tmp_dir = ENV.fetch('TMPDIR', '/tmp')
    FileUtils.mkdir_p(tmp_dir)
    Tempfile::Dir = tmp_dir
  end
end
