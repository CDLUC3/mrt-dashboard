require 'socket'

rails_env = ENV['RAILS_ENV'] || 'production'

# 16 workers and 1 master
worker_processes (rails_env == 'production' ? 8 : 2)

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

pid File.join(Dir.pwd, "log", "unicorn.pid")

# timeout is long because unicorn is serving up files
timeout 120

listen "#{Socket.gethostname}:26181"

logger Logger.new(File.join(Dir.pwd, "log", "unicorn.log"))
