require 'merritt/atom'

namespace :atom do
  desc 'Generic Atom to Merritt processor'
  FeedProcessor = Merritt::Atom::FeedProcessor
  task :update, FeedProcessor::ARG_KEYS => :environment do |_, args|
    processor = FeedProcessor.new(args)
    processor.process_feed!
  end
end
