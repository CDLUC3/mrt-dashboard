APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chomp(';') : 'no-deploy-tag'

# If SSM_ROOT_PATH is not set, assume that this is a capistrano build step
if ENV.fetch('SSM_ROOT_PATH', '').empty? && ENV.fetch('SSM_SKIP_RESOLUTION', '').empty?
  LDAP_CONFIG = {}
  ATOM_CONFIG = {}
  APP_CONFIG = {}
else
  LDAP_CONFIG = Uc3Ssm::ConfigResolver.new({def_value: 'NOT_APPLICABLE'}).resolve_file_values({file: 'config/ldap.yml', return_key: Rails.env})
  ATOM_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/atom.yml', return_key: Rails.env})
  APP_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/app_config.yml', return_key: Rails.env})
end
  