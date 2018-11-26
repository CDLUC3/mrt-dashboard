require 'rake'

RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.load_tasks
  end
end

def invoke_task(task_name, *args)
  task = Rake::Task[task_name]
  task.reenable # allow tasks to be run multiple times per spec
  task.invoke(*args)
end
