require 'nokogiri'

module Merritt
  module Atom
    class EntryProcessor
      include Merritt::Atom::Util

      # 'workaround for funky site'
      # https://github.com/CDLUC3/mrt-dashboard/blob/3793a10252b964cb861ca15ff676ccc6c637898d/lib/tasks/atom.rake#L144-#L145
      PREFETCH_OPTIONS = { 'Accept' => 'text/html, */*' }.freeze

      attr_reader :entry, :harvester

      def initialize(entry:, harvester:)
        @entry = entry
        @harvester = harvester
      end

      def process_entry!
        return if already_up_to_date?

        obj = new_ingest_object
        log_info("Ready to submit id: #{@local_id}")
        links.each { |link| add_component(obj, link) }
        harvester.start_ingest(obj)
      end

      def atom_id
        xpath_content(entry, 'atom:id')
      end

      def local_id
        @local_id ||= begin
          secondary_local_id = xpath_content(entry, 'nx:identifier')
          if secondary_local_id
            "#{primary_local_id};#{secondary_local_id}"
          else
            primary_local_id
          end
        end
      end

      def already_up_to_date?
        @already_up_to_date ||= existing_object && existing_object.modified >= atom_updated
      end

      private

      def existing_object
        InvObject
          .where('erc_where LIKE ?', "%#{primary_local_id}%")
          .joins(:inv_collections)
          .where(inv_collections: { ark: harvester.collection_ark })
          .first
      end

      def primary_local_id
        @primary_local_id ||= xpath_content(entry, 'dc:identifier')
      end

      def new_ingest_object
        harvester.new_ingest_object(
          local_id: local_id,
          erc_who: dc_creator || atom_author_names,
          erc_what: dc_title || atom_title,
          erc_when: dc_date || atom_published,
          erc_where: archival_id, # TODO: find out how archival_id was supposed to work
          erc_when_created: atom_published,
          erc_when_modified: atom_updated
        )
      end

      def add_component(obj, link)
        uri = to_uri(link['href'])
        harvester.add_credentials!(uri)

        checksum = xpath_content(link, 'opensearch:checksum')
        digest = to_digest(checksum)

        name = link['href'].sub(%r{^https?://}, '')

        # TODO: do we even support prefetch any more?
        obj.add_component(uri, name: name, digest: digest, prefetch: true, prefetch_options: PREFETCH_OPTIONS)
      end

      def to_digest(checksum)
        return if checksum.blank? # includes nil, at least in Rails

        Mrt::Ingest::MessageDigest::MD5.new(checksum)
      end

      def links
        @links ||= entry.xpath('atom:link', NS)
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
        @archival_id ||= links.select { |u| u[:rel] == 'archival' }.first
      end

    end
  end
end
