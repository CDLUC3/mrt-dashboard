require 'merritt/atom'

# TODO: make these non-constants
DELAY = Merritt::Atom::DEFAULT_DELAY
BATCH_SIZE = Merritt::Atom::DEFAULT_BATCH_SIZE

namespace :atom do
  desc 'Generic Atom to Merritt processor'
  task :update, Merritt::Atom::Harvester::ARG_KEYS => :environment do |_, task_args|
    arg_hash = task_args.to_h
    delay, batch_size = throttler(task_args.extras)
    args = arg_hash.merge(delay: delay.to_i, batch_size: batch_size.to_i)
    processor = Merritt::Atom::Harvester.new(args)
    processor.process_feed!
  end

  def throttler(extras)
    return extras if extras.any?
    [DELAY, BATCH_SIZE]
  end
end
