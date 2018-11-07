module Merritt
  module Atom
    # noinspection RubyTooManyInstanceVariablesInspection
    class FeedProcessor
      include Merritt::Atom::Util

      ARG_KEYS = %i[starting_point submitter profile collection_ark feed_update_file].freeze

      attr_reader :starting_point
      attr_reader :submitter
      attr_reader :profile
      attr_reader :collection_ark
      attr_reader :feed_update_file
      attr_reader :delay
      attr_reader :batch_size

      # rubocop:disable Metrics/ParameterLists
      def initialize(starting_point:, submitter:, profile:, collection_ark:, feed_update_file:, delay:, batch_size:)
        @starting_point = starting_point
        @submitter = submitter
        @profile = profile
        @collection_ark = collection_ark
        @feed_update_file = feed_update_file
        @delay = delay
        @batch_size = batch_size
      end
      # rubocop:enable Metrics/ParameterLists

      def process_feed!
        process_from(starting_point)
      ensure
        join_server!
      end

      def last_feed_update
        return NEVER unless feed_update_file_exists?
        @last_feed_update ||= begin
          feed_update_str = File.read(feed_update_file)
          parse_time(feed_update_str)
        end
      end

      def one_time_server
        @one_time_server ||= begin
          server = Mrt::Ingest::OneTimeServer.new
          server.start_server
          server
        end
      end

      def ingest_client
        # TODO: validate config?
        @ingest_client ||= Mrt::Ingest::Client.new(APP_CONFIG['ingest_service'])
      end

      def join_server!
        @one_time_server.join_server if @one_time_server
      rescue StandardError => e
        log_error('Error joining server', e)
      end

      private

      def pause_file_path
        @pause_file_path ||= "#{ENV['HOME']}/dpr2/apps/ui/atom/PAUSE_ATOM_#{profile}"
      end

      def pause_file_exists?
        File.exist?(pause_file_path)
      end

      def feed_update_file_exists?
        @feed_update_file_exists ||= File.exist?(feed_update_file)
      end

      def process_from(page_url)
        return unless page_url
        while pause_file_exists?
          log_info("Pausing processing #{profile} for #{delay} seconds")
          sleep(delay)
        end
        page_processor = PageProcessor.new(page_url: page_url, feed_processor: self)
        next_page = page_processor.process_page!
        process_from(next_page)
      end

    end
  end
end
