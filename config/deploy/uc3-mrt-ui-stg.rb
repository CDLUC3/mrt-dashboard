# For manually deploying to nodes in fqsn 'uc3-mrt-ui-stg'.
# We will always be deploying to localhost.
#
# Usage:
#   bundle exec cap uc3-mrt-ui-stg deploy BRANCH=<git-ref>
#
set :rails_env, 'stage'
ENV['SSM_ROOT_PATH'] = '/uc3/mrt/stg/'
raise "Environment var 'BRANCH' not defined" unless ENV['BRANCH']

puts "Deploying cap_environment 'uc3-mrt-ui-stg':"
puts "  branch: #{fetch(:branch)}"
puts "  rails_env: #{fetch(:rails_env)}"
puts "  SSM_ROOT_PATH: #{ENV.fetch('SSM_ROOT_PATH', nil)}"
server 'localhost', user: fetch(:user), roles: %w[web app]
