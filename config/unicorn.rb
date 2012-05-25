require 'socket'

rails_env = ENV['RAILS_ENV'] || 'production'

# 16 workers and 1 master
worker_processes 16

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

pid File.join(Dir.pwd, "log", "unicorn.pid")

# timeout is long because we upload files
# switch to nginx to fix
timeout 3000

logger Logger.new(File.join(Dir.pwd, "log", "unicorn.log"))
