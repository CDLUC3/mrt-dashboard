require 'nokogiri'

module Merritt
  module Atom
    class XmlProcessor
      include Merritt::Atom::Util

      NS = {
        'atom' => 'http://www.w3.org/2005/Atom',
        'xhtml' => 'http://www.w3.org/1999/xhtml'
      }.freeze

      attr_reader :atom_xml

      def initialize(atom_xml:, feed_processor:)
        @atom_xml = atom_xml
      end

      # @return The next page, or nil if there is no next page
      def process_xml!
        updated_str = xpath_content('//atom:updated')
        next_page
      end

      private

      def updated
        updated_elem = first_xpath_match('//atom:updated')
        return unless updated_elem
        updated_str = updated_elem.content
        parse_time(updated_str)
      end

      def first_xpath_match(query)
        nodes = atom_xml.xpath(query, NS)
        return unless nodes && !nodes.empty?
        nodes[0]
      end

      def xpath_content(query)
        match = first_xpath_match(query)
        return unless match
        match.content
      end

      def next_page
        xpath_content('/atom:feed/atom:link[@rel="next"]/@href')
      end
    end
  end
end
