module Merritt
  module Atom
    DEFAULT_DELAY = 300
    DEFAULT_BATCH_SIZE = 1 # Nuxeo doesn't like us to queue up too many requests

    require_relative 'atom/util'
    require_relative 'atom/feed_processor'
    require_relative 'atom/page_client'
    require_relative 'atom/harvester'
  end
end
