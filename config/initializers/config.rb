def load_config(name)
  path = File.join(Rails.root, 'config', name)
  if !File.exists?(path)
    raise Exception.new("Config file #{name} not found!")
  elsif File.size(path) == 0
    raise Exception.new("Config file #{name} is empty!")
  else
    conf = YAML.load_file(path)
    conf_env = conf[Rails.env]
    if conf_env.class == String
      return conf[conf_env]
    else
      return conf_env
    end
  end
end

LDAP_CONFIG = load_config('ldap.yml')
ATOM_CONFIG = load_config('atom.yml')
APP_CONFIG = load_config('app_config.yml')
