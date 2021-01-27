APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chomp(';') : 'no-deploy-tag'

raise "Environment var 'SSM_ROOT_PATH' not defined" unless ENV['SSM_ROOT_PATH']

LDAP_CONFIG = Uc3Ssm::ConfigResolver.new({def_value: 'NOT_APPLICABLE'}).resolve_file_values({file: 'config/ldap.yml', return_key: Rails.env})
ATOM_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/atom.yml', return_key: Rails.env})
APP_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/app_config.yml', return_key: Rails.env})
  