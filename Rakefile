# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)
MrtDashboard::Application.load_tasks

# ------------------------------------------------------------
# Coverage & profiling

desc 'Run all tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:spec].invoke
end

desc 'Run all tests with profiling'
task :profile do
  ENV['PROFILE'] = 'true'
  Rake::Task[:spec].invoke
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Defaults

# clear rspec/rails default :spec task in favor of :coverage
Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

desc 'Run unit tests, check test coverage, check code style'
task default: %i[coverage rubocop]
