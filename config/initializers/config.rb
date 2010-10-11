def load_config(name)
  conf = YAML.load_file(File.join(Rails.root, "config", name))
  conf_env = conf[Rails.env]
  if conf_env.class == String then
    return conf[conf_env]
  else
    return conf_env
  end
end

LDAP_CONFIG = load_config("ldap.yml")
