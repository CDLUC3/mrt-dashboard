# When running cap deploy from puppet, we will always be installing to localhost
#
set :user         ENV['USER']            || 'dpr2'
server 'localhost', user: fetch(:user), roles: %w[web app]
