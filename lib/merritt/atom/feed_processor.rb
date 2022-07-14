require 'nokogiri'

module Merritt
  module Atom
    class FeedProcessor
      include Merritt::Atom::Util

      FUTURE = Time.utc(9999)

      attr_reader :atom_xml, :harvester

      def initialize(atom_xml:, harvester:)
        @atom_xml = atom_xml
        @harvester = harvester
      end

      # @return [PageResult] the `<atom:updated/>` value from the feed and the URL of the next page, if any
      # rubocop:disable Metrics/AbcSize
      def process_xml!
        verify_collection_id!
        return if feed_up_to_date

        batches = atom_xml.xpath('//atom:entry', NS).each_slice(harvester.batch_size)
        batches.each_with_index do |batch, i|
          log_info("Processing batch #{i} of #{batches.size} (#{batch.size} entries)")
          any_up_to_date = process_batch(batch)
          no_more_batches = batches.size <= i + 1
          next if any_up_to_date || no_more_batches

          # :nocov:
          sleep(harvester.delay)
          # :nocov:
        end
        PageResult.new(atom_updated: atom_updated, next_page: next_page)
      end
      # rubocop:enable Metrics/AbcSize

      private

      def feed_up_to_date
        current_feed_update = feed_updated
        last_feed_update = harvester.last_feed_update
        up_to_date = current_feed_update < last_feed_update
      ensure
        log_info("Feed update date #{current_feed_update} #{up_to_date ? 'older' : 'newer'} than last_feed_update #{last_feed_update}")
      end

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

        # :nocov:
        msg = <<~MSG
          Merritt Collection ID from feed XML does not match collection ARK passed to Rake task;
          expected '#{expected_id}', was #{"'#{merritt_collection_id}'" || 'nil'}
        MSG
        raise ArgumentError, msg.strip.tr("\n", ' ')
        # :nocov:
      end

      # noinspection RubyScope
      def process_entry(entry)
        entry_processor = EntryProcessor.new(entry: entry, harvester: harvester)
        atom_id = entry_processor.atom_id
        local_id = entry_processor.local_id
        log_info("Attempting to process id: #{local_id}")
        entry_processor.process_entry!
        entry_processor.already_up_to_date?
      rescue StandardError => e
        # :nocov:
        atom_id_str = (defined?(atom_id) && atom_id) || '(unknown)'
        local_id_str = (defined?(local_id) && local_id) || '(unknown)'
        log_error("Error processing entry with Atom ID #{atom_id_str} (local ID: #{local_id_str})", e)
        # :nocov:
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
