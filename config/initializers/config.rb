require 'uc3-ssm'
require 'socket'

# name - config file to process
# resolve_key - partially process config file using this as a root key - use this to prevent unnecessary lookups
# return_key - return values for a specific hash key - use this to filter the return object
def load_uc3_config(name:, resolve_key: nil, return_key: nil)
  myenv = Socket.gethostname.match?(/uc3-.*-/) ? Socket.gethostname.gsub(/uc3-.*-/, '') : 'stg'
  resolver = Uc3Ssm::ConfigResolver.new(
    def_value: 'NOT_APPLICABLE',
    region: ENV.key?('AWS_REGION') ? ENV['AWS_REGION'] : 'us-west-2',
    ssm_root_path: ENV.key?('SSM_ROOT_PATH') ? ENV['SSM_ROOT_PATH'] : "/uc3/mrt/#{myenv}/"
  )
  path = File.join(Rails.root, 'config', name)
  resolver.resolve_file_values(file: path, resolve_key: resolve_key, return_key: return_key)
end

LDAP_CONFIG = load_uc3_config(name: 'ldap.yml', resolve_key: Rails.env, return_key: Rails.env)
ATOM_CONFIG = load_uc3_config(name: 'atom.yml', resolve_key: Rails.env, return_key: Rails.env)
APP_CONFIG = load_uc3_config(name: 'app_config.yml', resolve_key: Rails.env, return_key: Rails.env)
