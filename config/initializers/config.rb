require 'uc3-ssm'

# name - config file to process
# return_key - return values for a specific hash key - use this to filter the return object
def load_uc3_config(name:, return_key: nil)
  # NOTE: ENV does not seemed to be initialized at this time
  puts "***"
  puts `echo $SSM_ROOT_PATH`.chomp
  resolver = Uc3Ssm::ConfigResolver.new(
    def_value: 'NOT_APPLICABLE',
    ssm_root_path: `echo $SSM_ROOT_PATH`.chomp
  )
  path = File.join(Rails.root, 'config', name)
  resolver.resolve_file_values(file: path, return_key: return_key)
end

LDAP_CONFIG = load_uc3_config(name: 'ldap.yml', return_key: Rails.env)
ATOM_CONFIG = load_uc3_config(name: 'atom.yml', return_key: Rails.env)
APP_CONFIG = load_uc3_config(name: 'app_config.yml', return_key: Rails.env)

APP_VERSION = File.exist?('.version') ? File.read('.version').chop.chomp(';') : 'no-deploy-tag'
