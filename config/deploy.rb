require 'uc3-ssm'

# Config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'

set :application,      'merritt-ui'
set :user,             ENV['USER']            || 'dpr2'
set :home,             ENV['HOME']            || '/dpr2'
set :deploy_to,        ENV['CAP_DEPLOY_TO']   || '/dpr2/apps/ui'
set :rails_env,        ENV['RAILS_ENV']       || 'production'
set :repo_url,         ENV['APP_REPO']        || 'https://github.com/cdluc3/mrt-dashboard.git'
set :branch,           ENV['APP_BRANCH']      || 'master'
set :config_repo_url,  ENV['CONFIG_REPO']     || 'git@github.com:cdlib/mrt-dashboard-config.git'
set :config_tag,       ENV['CONFIG_TAG']      || 'master'
set :config_repo_name, 'mrt-dashboard-config'
set :puma_pid,         "#{fetch(:deploy_to)}/shared/pid/puma.pid"
set :puma_log,         "#{fetch(:deploy_to)}/shared/log/puma.log"
set :puma_port,        '26181'

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
#before 'deploy', 'deploy:prompt_for_tag'
# Update config/atom repo before deployment only
before 'deploy', 'deploy:update_config'
before 'deploy', 'deploy:update_atom'
#after  'deploy', 'bundle:install'
#after  'deploy', 'deploy:update_env'

namespace :deploy do
  before :compile_assets, :env_setup

  #desc 'Prompt for branch'
  #task :prompt_for_tag do
  #  on roles(:app) do
  #    puts 'Usage: [CONF_TAG=<config repo tag>] TAG=<UI repo tag> cap mrt-ui-dev deploy'
  #    ask :branch, 'master' unless ENV['TAG']
  #    set :branch, ENV['TAG'] if ENV['TAG']
  #    puts "Setting branch to: #{fetch(:branch)}"
  #  end
  #end

  desc 'Update configuration'
  task :update_config do
    on roles(:app) do
      shared_dir = "#{fetch(:deploy_to)}/shared"
      repo_name = "#{fetch(:config_repo_name)}"
      repo_url = "#{fetch(:config_repo_url)}"
      rev = "#{fetch(:config_tag)}"

      # make sure config repo is checked out & symlinked
      unless test("[ -d #{shared_dir}/#{repo_name} ]")
        # move hard-coded config directory out of the way if needed
        config_dir = "#{shared_dir}/config"
        execute "mv #{config_dir} #{config_dir}.old" if test("[ -d #{config_dir} ]")
        within shared_dir do
          # clone config repo and link it as config directory
          execute 'git', 'clone', "#{repo_url}", "#{repo_name}"
          execute 'ln', '-s', "#{repo_name}", 'config'
        end
      end

      # update config repo
      within "#{shared_dir}/#{repo_name}" do
        puts "Updating #{repo_url} to #{rev}"
        execute 'git', 'fetch', '--all', '--tags'
        execute 'git', 'reset', '--hard', "origin/#{rev}"
      end
    end
  end


  desc 'Setup ENV Variables'
  task :env_setup do
    on roles(:app), wait: 1 do
      ssm = Uc3Ssm::ConfigResolver.new
      master_key = ssm.parameter_for_key('ui/master_key')
      f = File.open("#{release_path}/config/master.key", 'w')
      f.puts master_key
      f.close
    end
  end

  #desc 'Setup ENV variables'
  #task :update_env do
  #  on roles(:app), wait: 1 do
  #    master_key = capture('source $HOME/.profile.d/uc3-aws-util.sh && get_ssm_value_by_name ui/master_key')
  #    target = "#{release_path}/config/master.key"
  #    execute("echo #{master_key} > #{target}")
  #    execute("ls -l #{target}")
  #  end
  #end

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

#namespace :bundle do
#  desc 'run bundle install and ensure all gem requirements are met'
#  task :install do
#    on roles(:app) do
#      execute "cd #{current_path} && bundle config set path $HOME/.gem"
#      execute "cd #{current_path} && bundle install --without=test"
#      execute "cd #{current_path} && bundle exec rake assets:precompile"
#    end
#  end
#end
