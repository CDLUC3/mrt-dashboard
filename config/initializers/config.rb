require 'uc3-ssm'

def load_uc3_config(name, railsenv = nil)
  path = File.join(Rails.root, 'config', name)
  conf = Uc3Ssm::ConfigResolver.new(
    "NOT_APPLICABLE",
    ENV.key?('AWS_REGION') ? ENV['AWS_REGION'] : "us-west-2",
    ENV.key?('SSM_ROOT_PATH') ? ENV['SSM_ROOT_PATH'] : "/uc3/mrt/stg/"
  ).resolve_file_values(path)
  return conf unless railsenv
  conf_env = conf[railsenv]
  conf_env.class == String ? conf[conf_env] : conf_env
end

LDAP_CONFIG = load_uc3_config('ldap.yml', Rails.env)
ATOM_CONFIG = load_uc3_config('atom.yml', Rails.env)
APP_CONFIG = load_uc3_config('app_config.yml', Rails.env)
