# Note: Define most command line vaiables here. This is a switch
#       from the old style incorporated in Unicorn.
#  - mreyes -

# Variables
application_path = ENV['RAILS_ROOT'] || '/dpr2/apps/ui'

# The directory to operate out of.
#
# The default is the current directory.
directory application_path.to_s

# Load "path" as a rackup file.
#
# The default is "config.ru".
rackup      "#{application_path}/current/config.ru"

# Set the environment in which the rack's app will run. The value must be a string.
#
# The default is "development".
#
environment ENV['RAILS_ENV'] || 'stage'

# Daemonize the server into the background. Highly suggest that
# this be combined with "pidfile" and "stdout_redirect".
#
# The default is "false".
#
# daemonize true

# Store the pid of the server in the file at "path".
#
# pidfile ENV['RAILS_ENV']/shared/pid/puma.pid
pidfile "#{application_path}/shared/pid/puma.pid"

# Use "path" as the file to store the server info state. This is
# used by "pumactl" to query and control the server.
#
state_path "#{application_path}/shared/pid/puma.state"

# Redirect STDOUT and STDERR to files specified. The 3rd parameter
# ("append") specifies whether the output is appended, the default is
# "false".
#
stdout_redirect "#{application_path}/shared/log/puma.log", "#{application_path}/shared/log/puma_error.log", true

# Configure "min" to be the minimum number of threads to use to answer
# requests and "max" the maximum.
#
# The default is "0, 16".
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 16)
threads 0, threads_count

# # Bind the server to "url". "tcp://", "unix://" and "ssl://" are the only
# accepted protocols.
#
# The default is "tcp://0.0.0.0:9292".
#
port ENV['PORT'] || 26_181
# bind tcp://0.0.0.0:26181

# How many worker processes to run.  Typically this is set to
# to the number of available cores.
#
# The default is "0".
#
workers Integer(ENV['WEB_CONCURRENCY'] || 1)

# Preload the application before starting the workers; this conflicts with
# phased restart feature. (off by default)
preload_app!

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. This is
# not a request timeout, it is to protect against a hung or dead process.
# Setting this value will not protect against slow requests.
# Default value is 60 seconds.
#
# worker_timeout 60

# Unsure that this is a application timeout!!!!  - mreyes -
# Rack::Timeout.timeout = 7200  # seconds

# Code to run in a worker before it starts serving requests.
#
# This is called everytime a worker is to be started.
on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
