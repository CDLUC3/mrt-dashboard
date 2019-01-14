require 'merritt/atom'

# TODO: make these non-constants
DELAY = Merritt::Atom::DEFAULT_DELAY
BATCH_SIZE = Merritt::Atom::DEFAULT_BATCH_SIZE

namespace :atom do
  desc 'Generic Atom to Merritt processor'
  task :update, Merritt::Atom::Harvester::ARG_KEYS => :environment do |_, task_args|
    arg_hash = task_args.to_h

    args = throttle(arg_hash)
    args ||= arg_hash.merge(delay: DELAY, batch_size: BATCH_SIZE)
    processor = Merritt::Atom::Harvester.new(args)
    processor.process_feed!
  end

  def throttle(args)
    return args if args.key?('delay') && args.key?('batch_size')
    nil
  end
end
