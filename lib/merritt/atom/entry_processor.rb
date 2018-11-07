require 'nokogiri'

module Merritt
  module Atom
    class EntryProcessor
      include Merritt::Atom::Util

      attr_reader :entry
      attr_reader :feed_processor

      def initialize(entry:, feed_processor:)
        @entry = entry
        @feed_processor = feed_processor
      end

      def process_entry!
        obj = Mrt::Ingest::IObject.new(erc: erc, server: one_time_server, local_identifier: local_id, archival_id: archival_id)
        urls.each { |url| add_url(obj, url) }
        object.start_ingest(ingest_client, profile, submitter)
      end

      def add_url(obj, url)
        # code here
      end

      def erc
        # TODO: test each fallback
        @erc ||= {
          'who' => dc_creator || atom_author_names,
          'what' => dc_title || atom_title,
          'when' => dc_date || atom_published,
          'where' => archival_id, # TODO: find out how this was supposed to work,
          'when/created' => atom_published,
          'when/modified' => atom_updated
        }
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

      private

      # TODO: make feed_processor create & submit the object so we can kill these

      def profile
        feed_processor.profile
      end

      def submitter
        feed_processor.submitter
      end

      def one_time_server
        feed_processor.one_time_server
      end

      def inget_client
        feed_processor.ingest_client
      end

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
