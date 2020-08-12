require 'uc3-ssm'

def load_config(name)
  path = File.join(Rails.root, 'config', name)
  conf = Uc3Ssm::ConfigResolver.new("NOT_APPLICABLE", "us-west-2", "/uc3/mrt/stg/").resolve_file_values(path)
  conf_env = conf[Rails.env]
  conf_env.class == String ? conf[conf_env] : conf_env
end

LDAP_CONFIG = load_config('ldap.yml')
ATOM_CONFIG = load_config('atom.yml')
APP_CONFIG = load_config('app_config.yml')
DB_CONFIG = load_config('database.yml')

ENV['DATABASE_URL']="#{DB_CONFIG['adapter']}:#{DB_CONFIG['username']}:#{DB_CONFIG['password']}@#{DB_CONFIG['host']}:#{DB_CONFIG['port']}/#{DB_CONFIG['database']}"

#SSM_ENV = load_config('ssm-env.yml')

#puts "TBTB ***"
#puts SSM_ENV
