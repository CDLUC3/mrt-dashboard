# For manually deploying to nodes in fqsn 'uc3-mrt-ui-stg'
#
# Usage:
#   cap uc3-mrt-ui-stg deploy BRANCH=<git_tag|git_branch>

set :rails_env, 'stage'
ENV['SSM_ROOT_PATH'] = '/uc3/mrt/stg/'
raise "Environment var 'BRANCH' not defined" unless ENV['BRANCH'] 

# We will always be installing to localhost
server 'localhost', user: fetch(:user), roles: %w[web app]
