require 'csv'
require 'erb'
require 'ostruct'

module Merritt
  module Atom
    class CSHGenerator
      ARG_KEYS = %i[nuxeo_collection_name feed_url merritt_collection_mnemonic merritt_collection_ark merritt_collection_name].freeze
      ARK_QUALIFIER_REGEXP = %r{(?<=/)[^/]+$}
      REGISTRY_ID_REGEXP = /(?<=_)[0-9]+(?=\.atom$)/

      CSH_TEMPLATE = <<~ERB.freeze
        # setenv RAILS_ENV stage
        setenv PATH /dpr2/local/bin:${PATH}

        set date = `date +%Y%m%d`
        set base = /apps/dpr2/apps/ui/atom

        cd /dpr2/apps/ui/current

        # Nuxeo Collection
        #    Atom URL: <%= feed_url %>
        #    Registry ID: <%= registry_id %>
        #    Name: <%= nuxeo_collection_name %>
        #
        # Merritt Collection
        #    Collection ID: <%= merritt_collection_ark %>
        #    Name: <%= merritt_collection_name %>
        #    Mnemonic: <%= merritt_collection_mnemonic %>

        # To pause, uncomment...
        #touch PAUSE_ATOM_<%= merritt_collection_mnemonic %>_content

        # Last feed update, defined in atom.ldap
        # /dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_<%= registry_id %>-<%= collection_ark_qualifier %>

        set feedURL	= "<%= feed_url %>"
        set userAgent	= "Atom processor/<%= merritt_collection_name %>"
        set profile	= "<%= merritt_collection_mnemonic %>_content"
        set groupID	= "<%= merritt_collection_ark %>"
        set updateFile	= "/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_<%= registry_id %>-<%= collection_ark_qualifier %>"
        set log		= "${base}/logs/${profile}_${date}.log"

        # Log file
        bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

        # No log file
        # bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

        exit
      ERB

      attr_reader :collection_ark_qualifier
      attr_reader :registry_id

      attr_reader :nuxeo_collection_name
      attr_reader :feed_url
      attr_reader :merritt_collection_mnemonic
      attr_reader :merritt_collection_ark
      attr_reader :merritt_collection_name

      def initialize(nuxeo_collection_name:, feed_url:, merritt_collection_mnemonic:, merritt_collection_ark:, merritt_collection_name:)
        @nuxeo_collection_name = validate(nuxeo_collection_name, name: 'nuxeo_collection_name')
        @feed_url = validate(feed_url, name: 'feed_url')
        @merritt_collection_mnemonic = validate(merritt_collection_mnemonic, name: 'merritt_collection_mnemonic')
        @merritt_collection_ark = validate(merritt_collection_ark, name: 'merritt_collection_ark')
        @merritt_collection_name = validate(merritt_collection_name, name: 'merritt_collection_name')
        @collection_ark_qualifier = merritt_collection_ark.scan(ARK_QUALIFIER_REGEXP).first
        @registry_id = feed_url.scan(REGISTRY_ID_REGEXP).first
      end

      def generate_csh
        CSHGenerator.template.result(binding)
      end

      def filename
        sanitized_name = CSHGenerator.sanitize_name(nuxeo_collection_name)
        "#{registry_id}-#{sanitized_name}-#{merritt_collection_mnemonic}.csh"
      end

      private

      def validate(arg, name:)
        raise ArgumentError, "#{name} argument not found" unless arg
        raise ArgumentError, "#{name} argument '#{arg}' cannot be blank" if arg.strip == ''
        arg
      end

      class << self

        def template
          @template ||= ERB.new(CSH_TEMPLATE)
        end

        # noinspection RubyUnusedLocalVariable
        def generate_csh(nuxeo_collection_name:, feed_url:, merritt_collection_mnemonic:, merritt_collection_ark:, merritt_collection_name:)
          generator = CSHGenerator.new(
            nuxeo_collection_name: nuxeo_collection_name,
            feed_url: feed_url,
            merritt_collection_mnemonic: merritt_collection_mnemonic,
            merritt_collection_ark: merritt_collection_ark,
            merritt_collection_name: merritt_collection_name
          )
          generator.generate_csh
        end

        def sanitize_name(name)
          name.gsub(/[^A-Za-z0-9]+/, '-').gsub(/-+%/, '').gsub(/([a-z])-s/, '\\1s')
        end

        def from_csv(csv_data:, to_dir:)
          rows = CSV.parse(csv_data)
          rows.each do |row|
            generator = CSHGenerator.new(
              nuxeo_collection_name: row[0], feed_url: row[1],
              merritt_collection_mnemonic: row[2], merritt_collection_ark: row[3], merritt_collection_name: row[4]
            )
            File.open(File.join(to_dir, generator.filename), 'w') { |f| f.write(generator.generate_csh) }
          end
          rows.size
        end

      end
    end
  end
end
