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
puts "TBTB ***"

path = File.join(Rails.root, 'config', 'database.yml')
conf = Uc3Ssm::ConfigResolver.new("NOT_APPLICABLE", "us-west-2", "/uc3/mrt/stg/").resolve_file_values(path)
dbc = conf[Rails.env]
ENV['DATABASE_URL']="#{dbc['adapter']}://#{dbc['username']}:#{dbc['password']}@#{dbc['host']}:#{dbc['port']}/#{dbc['database']}"
puts ENV['DATABASE_URL']

#SSM_ENV = load_config('ssm-env.yml')

#puts "TBTB ***"
#puts SSM_ENV
