module Merritt
  module Atom
    DEFAULT_DELAY = 300
    DEFAULT_BATCH_SIZE = 10 # Can be problematic for George Fujimoto collection until Nuxeo server upgraded

    require_relative 'atom/util'
    require_relative 'atom/feed_processor'
    require_relative 'atom/page_client'
    require_relative 'atom/harvester'
  end
end
