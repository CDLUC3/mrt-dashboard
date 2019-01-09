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

      # @return [PageResult] the `<atom:updated/>` value from the feed and the URL of the next page, if any
      # rubocop:disable Metrics/AbcSize
      def process_xml!
        verify_collection_id!
        return if feed_updated < harvester.last_feed_update
        batches = atom_xml.xpath('//atom:entry', NS).each_slice(harvester.batch_size)
        batches.each_with_index do |batch, i|
          any_up_to_date = process_batch(batch)
          no_more_batches = batches.size <= i + 1
          next if any_up_to_date || no_more_batches
          sleep(harvester.delay)
        end
        PageResult.new(atom_updated: atom_updated, next_page: next_page)
      end
      # rubocop:enable Metrics/AbcSize

      private

      def process_batch(batch)
        any_up_to_date = false
        batch.each do |entry|
          entry_up_to_date = process_entry(entry)
          any_up_to_date ||= entry_up_to_date
        end
        any_up_to_date
      end

      def verify_collection_id!
        expected_id = harvester.collection_ark
        return if expected_id == merritt_collection_id
        msg = <<~MSG
          Merritt Collection ID from feed XML does not match collection ARK passed to Rake task;
          expected '#{expected_id}', was #{"'#{merritt_collection_id}'" || 'nil'}
        MSG
        raise ArgumentError, msg.strip.tr("\n", ' ')
      end

      def process_entry(entry)
        entry_processor = EntryProcessor.new(entry: entry, harvester: harvester)
        atom_id = entry_processor.atom_id
        local_id = entry_processor.local_id
        entry_processor.process_entry!
        entry_processor.already_up_to_date?
      rescue StandardError => e
        atom_id_str = atom_id || '(unknown)'
        local_id_str = local_id || '(unknown)'
        log_error("Error processing entry with Atom ID #{atom_id_str} (local ID: #{local_id_str})", e)
      end

      def merritt_collection_id
        # TODO: what if this doesn't match the one passed to the rake task?
        @merritt_collection_id ||= xpath_content(atom_xml, '//atom:merritt_collection_id')
      end

      def atom_updated
        @atom_updated ||= xpath_content(atom_xml, '//atom:updated')
      end

      def feed_updated
        parse_time(atom_updated, default: FUTURE)
      end

      def next_href
        @next_href ||= xpath_content(atom_xml, '/atom:feed/atom:link[@rel="next"]/@href')
      end

      def self_href
        @self_href ||= xpath_content(atom_xml, '/atom:feed/atom:link[@rel="self"]/@href')
      end

      def next_page
        next_href unless next_href == self_href
      end
    end
  end
end
