APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chomp(';') : 'no-deploy-tag'

if ENV.empty?
  puts "default: #{ENV}"
  LDAP_CONFIG = {}
  ATOM_CONFIG = {}
  APP_CONFIG = {}
else
  puts "Set ---- #{ENV}"
  LDAP_CONFIG = Uc3Ssm::ConfigResolver.new({def_value: 'NOT_APPLICABLE'}).resolve_file_values({file: 'config/ldap.yml', return_key: Rails.env})
  ATOM_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/atom.yml', return_key: Rails.env})
  APP_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/app_config.yml', return_key: Rails.env})
end
  