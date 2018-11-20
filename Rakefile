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

desc 'Run all tests with profiling (for full ruby-prof report, specify [calltree] or [html] format)'
task :profile, [:format] do |_, args|
  ENV['PROFILE'] = args.to_h.inspect
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
