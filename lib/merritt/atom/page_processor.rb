require 'nokogiri'
require 'rest-client'
require 'time'

module Merritt
  module Atom
    class PageProcessor
      include Merritt::Atom::Util

      attr_reader :page_url
      attr_reader :feed_processor

      def initialize(page_url:, feed_processor:)
        @page_url = page_url
        @feed_processor = feed_processor
      end

      # @return The next page, or nil if there is no next page
      def process_page!
        return unless (atom_xml = parse_xml)
        xml_processor = XmlProcessor.new(atom_xml: atom_xml, feed_processor: feed_processor)
        xml_processor.process_xml!
      end

      private

      def parse_xml
        tries = 0
        begin
          tries += 1
          response = RestClient.get(page_url, user_agent: "#{self.class} (https://merritt.cdlib.org)")
          Nokogiri::XML(response)
        rescue StandardError => e
          log_error("Error processing page #{page_url} (tries = #{tries})", e)
          retry if tries < 3
        end
      end
    end
  end
end
