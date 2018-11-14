require 'merritt/atom'

# TODO: make these non-constants
DELAY = 300
BATCH_SIZE = 1 # Nuxeo doesn't like us to queue up too many requests

namespace :atom do
  desc 'Generic Atom to Merritt processor'
  FeedProcessor = Merritt::Atom::Harvester
  task :update, FeedProcessor::ARG_KEYS => :environment do |_, task_args|
    arg_hash = task_args.to_h
    args = arg_hash.merge(delay: DELAY, batch_size: BATCH_SIZE)
    processor = FeedProcessor.new(args)
    processor.process_feed!
  end
end
