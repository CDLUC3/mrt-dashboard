# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'merritt-ui'
set :repo_url, 'https://hg.cdlib.org/mrt-dashboard'

set :deploy_to, '/dpr2/apps/ui'
set :scm, :hg

set :stages, ["development", "stage", "production"]
# set branch based on env
if $RAILS_ENV == 'stage' 
	set :branch, 'stage'
elsif $RAILS_ENV == 'production' 
	set :branch, 'prod'
else
	set :branch, 'default'
end

set :default_env, { path: "/dpr2/local/bin:$PATH" }

# persistent dirs
set :linked_files, %w{config/database.yml config/ldap.yml}
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

  desc 'Stop Unicorn'
  task :stop do
    on roles(:app) do
      if test("[ -f #{fetch(:unicorn_pid)} ]")
        execute "cd #{deploy_to}/current; kill -15 `cat #{fetch(:unicorn_pid)}`"
      end
    end
  end

  desc 'Start Unicorn'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "cd #{deploy_to}/current; bundle exec unicorn --config-file config/unicorn/#{fetch(:rails_env)}.rb --port #{fetch(:unicorn_port)} --env #{fetch(:rails_env)} --daemonize"
        end
      end
    end
  end
  before "deploy:start", "bundle:install"

  desc 'Status Unicorn'
  task :status do
    on roles(:app) do
       # check pid
       execute "cd #{deploy_to}/current; cat #{fetch(:unicorn_pid)} | xargs ps -lp"
    end
  end

  desc 'Restart Unicorn'
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
