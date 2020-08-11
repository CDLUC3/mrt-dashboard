require 'uc3-ssm'

def load_config(name)
  path = File.join(Rails.root, 'config', name)
  conf = Uc3Ssm::ConfigResolver.new.resolve_file_values(path)
  conf_env = conf[Rails.env]
  conf_env.class == String ? conf[conf_env] : conf_env
end

LDAP_CONFIG = load_config('ldap.yml')
ATOM_CONFIG = load_config('atom.yml')
APP_CONFIG = load_config('app_config.yml')
SSM_ENV = load_config('ssm-env.yml')

puts SSM_ENV
