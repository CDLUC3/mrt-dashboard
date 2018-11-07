require 'nokogiri'

module Merritt
  module Atom
    class EntryProcessor
      include Merritt::Atom::Util

      attr_reader :entry
      attr_reader :harvester

      def initialize(entry:, harvester:)
        @entry = entry
        @harvester = harvester
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def process_entry!
        obj = harvester.new_ingest_object(
          local_id: local_id,
          erc_who: dc_creator || atom_author_names,
          erc_what: dc_title || atom_title,
          erc_when: dc_date || atom_published,
          erc_where: archival_id, # TODO: find out how archival_id was supposed to work
          erc_when_created: atom_published,
          erc_when_modified: atom_updated
        )
        urls.each { |url| add_url(obj, url) }
        harvester.start_ingest(obj)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def add_url(obj, url)
        # code here
      end

      def urls
        @urls ||= entry.xpath('atom:link', NS).map { |link| to_url_hash(link) }
      end

      def dc_creator
        @dc_creator ||= xpath_content(entry, 'dc:creator')
      end

      def atom_author_names
        @atom_author_names ||= entry.xpath('atom:author/atom:name', NS).map(&:content).join('; ')
      end

      def dc_title
        @dc_title ||= xpath_content(entry, 'dc:title')
      end

      def atom_title
        @atom_title ||= xpath_content(entry, 'atom:title')
      end

      def dc_date
        @dc_date ||= xpath_content(entry, 'dc:date')
      end

      def atom_published
        @atom_published ||= xpath_content(entry, 'atom:published')
      end

      def atom_updated
        @atom_updated ||= xpath_content(entry, 'atom:updated')
      end

      def archival_id
        # TODO: why doesn't IObject actually use this, & if it did, how did it ever work?
        @archival_id ||= urls.select { |u| u[:rel] == 'archival' }.first
      end

      def local_id
        @local_id ||= xpath_content(entry, local_id_query)
      end

      def local_id_query
        harvester.local_id_query
      end

      private

      def to_url_hash(link)
        {
          rel: link['rel'],
          url: link['href'],
          checksum: xpath_content(link, 'opensearch:checksum'),
          name: link['href'].sub(%r{^https?://}, '')
        }
      end
    end
  end
end
