require 'nokogiri'

module Merritt
  module Atom
    class FeedProcessor
      include Merritt::Atom::Util

      FUTURE = Time.utc(9999)

      attr_reader :atom_xml
      attr_reader :harvester

      def initialize(atom_xml:, harvester:)
        @atom_xml = atom_xml
        @harvester = harvester
      end

      # @return The next page, or nil if there is no next page
      def process_xml!
        return if feed_updated < harvester.last_feed_update
        atom_xml.xpath('//atom:entry', NS).each do |entry|
          entry_processor = EntryProcessor.new(entry: entry, harvester: harvester)
          entry_processor.process_entry!
        end
        next_page
      end

      private

      def collection_ark
        # TODO: what if this doesn't match the one passed to the rake task?
        @collection_ark ||= xpath_content(atom_xml, '//atom:merritt_collection_id')
      end

      def feed_updated
        updated_elem = atom_xml.at_xpath('//atom:updated', NS)
        parse_time(updated_elem && updated_elem.content, default: FUTURE)
      end

      def next_page
        xpath_content(atom_xml, '/atom:feed/atom:link[@rel="next"]/@href')
      end
    end
  end
end
