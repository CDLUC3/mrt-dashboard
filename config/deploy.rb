require 'uc3-ssm'

# Config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'

set :application,      'merritt-ui'
set :user,             ENV.fetch('USER', nil) || 'dpr2'
set :home,             Dir.home || '/dpr2'
set :deploy_to,        ENV.fetch('DEPLOY_TO', nil)       || '/dpr2/apps/ui'
set :rails_env,        ENV.fetch('RAILS_ENV', nil)       || 'production'
set :repo_url,         ENV.fetch('REPO_URL', nil)        || 'https://github.com/cdluc3/mrt-dashboard.git'
set :branch,           ENV.fetch('BRANCH', nil)          || 'master'

set :default_env,      { path: '$PATH' }
set :stages,           %w[local mrt-ui-dev stage production]
set :puma_pid,         "#{fetch(:deploy_to)}/shared/pid/puma.pid"
set :puma_log,         "#{fetch(:deploy_to)}/shared/log/puma.log"
set :puma_port,        '26181'

# persistent dirs
set :linked_files, %w[]
set :linked_dirs, %w[log pid]

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for keep_releases is 5
set :keep_releases, 5

# Gets the current Git tag and revision
set :version_number, `git describe --tags`

# Update config/atom repo before deployment only
after 'deploy', 'git:version'

namespace :git do
  desc 'Add the version file so that we can display the git version in the footer'
  task :version do
    on roles(:app), wait: 1 do
      execute "touch #{release_path}/.version"
      execute "echo '#{fetch :version_number}' >> #{release_path}/.version"
    end
  end
end

namespace :deploy do
  before :compile_assets, :ssm_param

  desc 'Set master.key from SSM ParameterStore'
  task :ssm_param do
    on roles(:app), wait: 1 do
      ssm = Uc3Ssm::ConfigResolver.new
      master_key = ssm.parameter_for_key('ui/master_key')
      f = File.open("#{release_path}/config/master.key", 'w')
      f.puts master_key
      f.close
    end
  end

end

# namespace :bundle do
#  desc 'run bundle install and ensure all gem requirements are met'
#  task :install do
#    on roles(:app) do
#      execute "cd #{current_path} && bundle config set path $HOME/.gem"
#      execute "cd #{current_path} && bundle install --without=test"
#      execute "cd #{current_path} && bundle exec rake assets:precompile"
#    end
#  end
# end
