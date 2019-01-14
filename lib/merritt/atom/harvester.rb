module Merritt
  module Atom
    # noinspection RubyTooManyInstanceVariablesInspection
    class Harvester
      include Merritt::Atom::Util

      ARG_KEYS = %i[starting_point submitter profile collection_ark feed_update_file].freeze

      attr_reader :starting_point
      attr_reader :submitter
      attr_reader :profile
      attr_reader :collection_ark
      attr_reader :feed_update_file
      attr_reader :delay
      attr_reader :batch_size

      attr_reader :atom_updated

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

      # rubocop:disable Metrics/ClassLength
      def process_feed!
        return unless feed_update_file_exists?
        log_info("Processing with batch size #{batch_size} and delay #{delay} seconds")
        process_from(starting_point)
        update_feed_update_file!
      ensure
        join_server!
      end
      # rubocop:enable Metrics/ClassLength

      def last_feed_update
        @last_feed_update ||= begin
          feed_update_str = File.read(feed_update_file)
          parse_time(feed_update_str)
        end
      end

      def update_feed_update_file!
        return unless atom_updated
        File.open(feed_update_file, 'w') { |f| f.puts(atom_updated) }
      end

      def local_id_query
        @local_id_query ||= ATOM_CONFIG["#{collection_ark}_localidElement"] || 'atom:id'
      end

      # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      def new_ingest_object(local_id:, erc_who:, erc_what:, erc_when:, erc_where:, erc_when_created:, erc_when_modified:)
        Mrt::Ingest::IObject.new(
          erc: {
            'who' => erc_who,
            'what' => erc_what,
            'when' => erc_when,
            'where' => erc_where,
            'when/created' => erc_when_created,
            'when/modified' => erc_when_modified
          },
          server: one_time_server,
          local_identifier: local_id,
          archival_id: erc_where # TODO: find out how archival_id was supposed to work,
        )
      end
      # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

      def start_ingest(ingest_object)
        ingest_object.start_ingest(ingest_client, profile, submitter)
      end

      def add_credentials!(uri)
        return unless uri.host.include?('nuxeo.cdlib.org')
        uri.user, uri.password = credentials
      end

      private

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

      def credentials
        @credentials ||= begin
          credentials_str = ATOM_CONFIG["#{collection_ark}_credentials"]
          credentials_str ? credentials_str.split(':') : [nil, nil]
        end
      end

      def join_server!
        @one_time_server.join_server if @one_time_server
      rescue StandardError => e
        log_error('Error joining server', e)
      end

      def pause_file_path
        @pause_file_path ||= "#{ENV['HOME']}/dpr2/apps/ui/atom/PAUSE_ATOM_#{profile}"
      end

      def feed_update_file_exists?
        @feed_update_file_exists ||= File.exist?(feed_update_file)
      end

      def process_from(page_url)
        return unless page_url
        while File.exist?(pause_file_path)
          log_info("Pausing processing #{profile} for #{delay} seconds")
          sleep(delay)
        end
        page_client = PageClient.new(page_url: page_url, harvester: self)
        return unless (result = page_client.process_page!)

        @atom_updated = result.atom_updated
        process_from(result.next_page)
      end

    end
  end
end
