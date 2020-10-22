module Merritt
  module Atom
    # DEFAULT_DELAY = 300
    # DEFAULT_BATCH_SIZE = 10 # Can be problematic for George Fujimoto collection until Nuxeo server upgraded
    DEFAULT_DELAY = 60
    DEFAULT_BATCH_SIZE = 1

    require_relative 'atom/util'
    require_relative 'atom/feed_processor'
    require_relative 'atom/entry_processor'
    require_relative 'atom/page_result'
    require_relative 'atom/page_client'
    require_relative 'atom/harvester'
    require_relative 'atom/csh_generator'
  end
end
