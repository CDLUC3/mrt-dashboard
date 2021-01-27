APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chop.chomp(";") : 'no-deploy-tag'

if ENV.fetch('SSM_ROOT_PATH', '').empty?
  puts " *** SSM_ROOT_PATH is empty, will set based on Rails.env"
  if Rails.env == 'production'
    ENV['SSM_ROOT_PATH'] = '/uc3/mrt/prd/'
  elsif Rails.env == 'stage'
    ENV['SSM_ROOT_PATH'] = '/uc3/mrt/stg/'
  else Rails.env == 'dev'
    ENV['SSM_ROOT_PATH'] = '/uc3/mrt/dev/'
  end
end

LDAP_CONFIG = Uc3Ssm::ConfigResolver.new({def_value: 'NOT_APPLICABLE'}).resolve_file_values({file: 'config/ldap.yml', return_key: Rails.env})
ATOM_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/atom.yml', return_key: Rails.env})
APP_CONFIG = Uc3Ssm::ConfigResolver.new.resolve_file_values({file: 'config/app_config.yml', return_key: Rails.env})
  