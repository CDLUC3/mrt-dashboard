require 'uc3-ssm'
require 'socket'

# name - config file to process
# return_key - return values for a specific hash key - use this to filter the return object
def load_uc3_config(name:, return_key: nil)
  myenv = Socket.gethostname.match?(/uc3-.*-/) ? Socket.gethostname.gsub(/uc3-.*-/, '') : 'stg'
  resolver = Uc3Ssm::ConfigResolver.new(
    def_value: 'NOT_APPLICABLE',
    region: ENV.key?('AWS_REGION') ? ENV['AWS_REGION'] : 'us-west-2',
    ssm_root_path: ENV.key?('SSM_ROOT_PATH') ? ENV['SSM_ROOT_PATH'] : "/uc3/mrt/#{myenv}/"
  )
  path = File.join(Rails.root, 'config', name)
  config = resolver.resolve_file_values(file: path, return_key: return_key)
end

LDAP_CONFIG = load_uc3_config(name: 'ldap.yml', return_key: Rails.env)
ATOM_CONFIG = load_uc3_config(name: 'atom.yml', return_key: Rails.env)
APP_CONFIG = load_uc3_config(name: 'app_config.yml', return_key: Rails.env)
