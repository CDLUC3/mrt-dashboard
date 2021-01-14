require 'uc3-ssm'

# Config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'

set :application, 'merritt-ui'
set :user         ENV['USER']            || 'dpr2'
set :home         ENV['HOME']            || '/dpr2'
set :rails_env,   ENV['RAILS_ENV']       || 'production'
set :branch,      ENV['CAP_BRANCH']      || 'master'
set :repo_url,    ENV['CAP_REPO']        || 'https://github.com/cdluc3/mrt-dashboard.git'
set :deploy_to,   ENV['CAP_DEPLOY_TO']   || '/dpr2/apps/ui'

set :puma_pid, "#{deploy_to}/shared/pid/puma.pid"
set :puma_log, "#{deploy_to}/shared/log/puma.log"
set :puma_port, '26181'

# set :scm, :git

set :stages, %w[local mrt-ui-dev stage production]

set :default_env, { path: '$HOME/local/bin:$PATH' }

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
after  'deploy', 'bundle:install'
after  'deploy', 'deploy:update_env'

namespace :deploy do
  desc 'Stop Puma'
  task :stop do
    on roles(:app) do
      execute "echo Capistrano stop has been deprecated. Use systemctl: \$ sudo systemctl stop puma"
    end
  end

  desc 'Start Puma'
  task :start do
    on roles(:app) do
      execute "echo Capistrano start has been deprecated. Use systemctl: \$ sudo systemctl start puma"
    end
  end

  desc 'Restart Puma'
  task :restart do
    on roles(:app) do
      execute "echo Capistrano restart has been deprecated. Use systemctl: \$ sudo systemctl restart puma"
    end
  end

  desc 'Status Puma'
  task :status do
    on roles(:app) do
      execute "echo Capistrano status has been deprecated. Use systemctl: \$ sudo systemctl status puma"
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

  desc 'Setup ENV variables'
  task :update_env do
    on roles(:app), wait: 1 do
      master_key = capture('source $HOME/.profile.d/uc3-aws-util.sh && get_ssm_value_by_name ui/master_key')
      target = "#{release_path}/config/master.key"
      execute("echo #{master_key} > #{target}")
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
      execute "cd #{current_path} && bundle config set path $HOME/.gem"
      execute "cd #{current_path} && bundle install --without=test"
      execute "cd #{current_path} && bundle exec rake assets:precompile"
    end
  end
end
