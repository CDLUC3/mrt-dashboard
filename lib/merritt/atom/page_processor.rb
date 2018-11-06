require 'nokogiri'
require 'rest-client'

module Merritt
  module Atom
    class PageProcessor
      NS = {
        "atom"  => "http://www.w3.org/2005/Atom",
        "xhtml" => "http://www.w3.org/1999/xhtml"
      }.freeze

      attr_reader :page_url
      attr_reader :atom_processor

      def initialize(page_url:, feed_processor:)
        @atom_processor = feed_processor
        @page_url = page_url
      end

      # @return The next page, or nil if there is no next page
      def process
        return unless (atom_xml = parse_xml)
        xpath_content(atom_xml, '/atom:feed/atom:link[@rel="next"]/@href')
      end

      private

      def parse_xml
        response = RestClient.get(page_url, user_agent: "#{self.class} (https://merritt.cdlib.org)" )
        Nokogiri::XML(response)
      end

      def xpath_content(node, query)
        nodes = node.xpath(query, NS)
        return unless (nodes && nodes.size > 0)
        nodes[0].content
      end
    end
  end
end
