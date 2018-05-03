# config valid only for Capistrano 3.1
lock '3.4.0'

set :application, 'merritt-ui'
set :repo_url, 'https://github.com/CDLUC3/mrt-dashboard'

set :deploy_to, '/dpr2/apps/ui'
set :scm, :git

set :stages, ["local", "mrt-ui-dev", "mrt-ui01-stg",  "mrt-ui02-stg", "production"]

set :default_env, { path: "/dpr2/local/bin:$PATH" }

# persistent dirs
set :linked_files, %w{config/database.yml config/ldap.yml config/atom.yml}
set :linked_dirs, %w{log pid}


# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do

  desc 'Stop Puma'
  task :stop do
    on roles(:app) do
      if test("[ -f #{fetch(:puma_pid)} ]")
        execute "cd #{deploy_to}/current; kill -15 `cat #{fetch(:puma_pid)}`"
      end
    end
  end

  desc 'Start Puma'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "cd #{deploy_to}/current; bundle exec puma -C config/puma/#{fetch(:rails_env)}.rb -e #{fetch(:rails_env)}"
        end
      end
    end
  end
  before "deploy:start", "bundle:install"

  desc 'Status Puma'
  task :status do
    on roles(:app) do
      if test("[ -f #{fetch(:puma_pid)} ]")
         # check pid
         execute "cd #{deploy_to}/current; cat #{fetch(:puma_pid)} | xargs ps -lp"
      end
    end
  end

  desc 'Restart Puma'
  task :restart do
    on roles(:app), wait: 5 do
       # do not implement, use stop/start instead
    end
  end

end

namespace :bundle do

  desc "run bundle install and ensure all gem requirements are met"
  task :install do
    on roles(:app) do
      execute "cd #{current_path} && bundle install --without=test"
    end
  end

end
