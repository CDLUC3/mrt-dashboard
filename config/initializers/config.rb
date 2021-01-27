APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chop.chomp(';') : 'no-deploy-tag'

# When running outside of a local/docker environment, the SSM_ROOT_PATH must be set
# - For Capistrano, this is set in ~/.bashrc
# - For Systemd, this is set in 'Environment'
# - For docker deployments, this can be passed in via docker-compose.
#   - SSM_SKIP_RESOLUTION indicates that all values will be resolved from the ENV
# - We support one additional config (dev/docker) that uses SSM for database credentials
raise ' *** SSM_ROOT_PATH is empty' if ENV.fetch('SSM_ROOT_PATH', '').empty? && ENV.fetch('SSM_SKIP_RESOLUTION', '').empty?

# when running in dev/docker, provide a default resolution value for any SSM values that will not be used
LDAP_CONFIG = Uc3Ssm::ConfigResolver.new({ def_value: 'NOT_APPLICABLE' })
                                    .resolve_file_values({ file: 'config/ldap.yml', return_key: Rails.env })
# when running in dev/docker, provide a default resolution value for any SSM values that will not be used
ATOM_CONFIG = Uc3Ssm::ConfigResolver.new({ def_value: 'NOT_APPLICABLE' })
                                    .resolve_file_values({ file: 'config/atom.yml', return_key: Rails.env })
# app_config.yml does not have any SSM values                                    
APP_CONFIG = Uc3Ssm::ConfigResolver.new
                                    .resolve_file_values({ file: 'config/app_config.yml', return_key: Rails.env })
