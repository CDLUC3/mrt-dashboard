# For manually deploying to nodes in fqsn 'uc3-mrt-ui-prd'
#
# Usage:
#   cap uc3-mrt-ui-prd deploy BRANCH=<git_tag|git_branch>

set :rails_env, 'production'
ENV['SSM_ROOT_PATH'] = '/uc3/mrt/prd/'
raise "Environment var 'BRANCH' not defined" unless ENV['BRANCH'] 

# We will always be installing to localhost
server 'localhost', user: fetch(:user), roles: %w[web app]
