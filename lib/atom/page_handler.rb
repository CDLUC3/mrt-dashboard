module Merritt
  module Atom
    class PageHandler
      attr_reader :page_url
      attr_reader :atom_processor

      def initialize(page_url:, atom_processor:)
        @atom_processor = atom_processor
        @page_url = page_url
      end

      # @return The next page, or nil if there is no next page
      def handle_page_and_get_next
        # do the thing
      end
    end
  end
end
