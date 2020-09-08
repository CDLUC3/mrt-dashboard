# config valid only for Capistrano 3.1
lock '3.4.1'

set :application, 'merritt-ui'
set :repo_url, 'https://github.com/CDLUC3/mrt-dashboard'

set :deploy_to, '/dpr2/apps/ui'
set :scm, :git

set :stages, ['local', 'mrt-ui-dev', 'stage', 'production']

set :default_env, { path: '/dpr2/local/bin:$PATH' }

# persistent dirs
# set :linked_files, %w[config/database.yml config/ldap.yml config/atom.yml]
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

# Prompt for TAG before deployment only
before 'deploy', 'deploy:prompt_for_tag'
# Update config/atom repo before deployment only
before 'deploy', 'deploy:update_config'
before 'deploy', 'deploy:update_atom'

namespace :deploy do

  desc 'Stop Puma'
  task :stop do
    on roles(:app) do
      execute "cd #{deploy_to}/current; kill -15 `cat #{fetch(:puma_pid)}`" if test("[ -f #{fetch(:puma_pid)} ]")
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
  before 'deploy:start', 'bundle:install'

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

  desc 'Prompt for branch'
  task :prompt_for_tag do
    on roles(:app) do
      puts 'Usage: [CONF_TAG=<config repo tag>] TAG=<UI repo tag> cap mrt-ui-dev deploy'
      ask :branch, 'master' unless ENV['TAG']
      set :branch, ENV['TAG'] if ENV['TAG']
      puts "Setting branch to: #{fetch(:branch)}"
    end
  end

  desc 'Update configuration'
  task :update_config do
    on roles(:app) do
      shared_dir = "#{deploy_to}/shared"
      config_repo = 'mrt-dashboard-config'

      # make sure config repo is checked out & symlinked
      unless test("[ -d #{shared_dir}/#{config_repo} ]")
        # move hard-coded config directory out of the way if needed
        config_dir = "#{shared_dir}/config"
        execute "mv #{config_dir} #{config_dir}.old" if test("[ -d #{config_dir} ]")
        within shared_dir do
          # clone config repo and link it as config directory
          execute 'git', 'clone', "git@github.com:cdlib/#{config_repo}"
          execute 'ln', '-s', config_repo, 'config'
        end
      end

      # check for specific config repo tag
      if ENV['CONF_TAG']
        set :config_tag, ENV['CONF_TAG']
        puts "Setting #{config_repo} tag to: #{fetch(:config_tag)}"
      else
        puts "Defaulting #{config_repo} to master"
      end

      # update config repo
      config_tag = fetch(:config_tag, 'master')
      within "#{shared_dir}/#{config_repo}" do
        puts "Updating #{config_repo} to #{config_tag}"
        execute 'git', 'fetch', '--all', '--tags'
        execute 'git', 'reset', '--hard', "origin/#{config_tag}"
      end
    end
  end

  desc 'Update Atom scripts'
  task :update_atom do
    on roles(:app) do
      puts 'Updating links to Atom scripts if necessary'
      shared_dir = "#{deploy_to}/shared"
      atom_dir = "#{deploy_to}/atom"
      atom_repo = 'mrt-dashboard-config/atom'

      # make sure atom dirs are present
      execute 'mkdir', atom_dir unless test("[ -d #{atom_dir} ]")
      log_dir = "#{atom_dir}/logs"
      execute 'mkdir', log_dir unless test("[ -d #{log_dir} ]")
      last_update_dir = "#{atom_dir}/LastUpdate"
      execute 'mkdir', last_update_dir unless test("[ -d #{last_update_dir} ]")
      lock_dir = "#{atom_dir}/LockFile"
      execute 'mkdir', lock_dir unless test("[ -d #{lock_dir} ]")

      # make sure atom repo is checked out
      unless test("[ -d #{shared_dir}/#{atom_repo} ]")
        puts "[ERROR] Could not find atom repo: #{shared_dir}/#{atom_repo}"
        return
      end

      # make sure atom repo is symlinked
      within atom_dir do
        execute 'ln', '-s', "#{shared_dir}/#{atom_repo}/bin", '.' unless test("[ -h #{atom_dir}/bin ]")
      end
    end
  end

end

namespace :bundle do

  desc 'run bundle install and ensure all gem requirements are met'
  task :install do
    on roles(:app) do
      execute "cd #{current_path} && bundle install --without=test"
      execute "cd #{current_path} && bundle exec rake assets:precompile"
    end
  end

end
