# For manually deploying to nodes in fqsn 'uc3-mrt-ui-prd'.
# We will always be deploying to localhost.
#
# Usage:
#   bundle exec cap uc3-mrt-ui-prd deploy BRANCH=<git-ref>
#
set :rails_env, 'production'
raise "Environment var 'SSM_ROOT_PATH' not defined" unless ENV['SSM_ROOT_PATH']
raise "Environment var 'BRANCH' not defined" unless ENV['BRANCH']

puts "Deploying cap_environment 'uc3-mrt-ui-prd':"
puts "  branch: #{fetch(:branch)}"
puts "  rails_env: #{fetch(:rails_env)}"
puts "  SSM_ROOT_PATH: #{ENV['SSM_ROOT_PATH']}"
server 'localhost', user: fetch(:user), roles: %w[web app]
