require 'csv'
require 'erb'
require 'ostruct'

module Merritt
  module Atom
    class CSHGenerator
      ARG_KEYS = %i[feed_url collection_ark collection_name collection_mnemonic].freeze
      ARK_QUALIFIER_REGEXP = %r{(?<=/)[^/]+$}

      CSH_TEMPLATE = <<~ERB.freeze
        # setenv RAILS_ENV stage
        setenv PATH /dpr2/local/bin:${PATH}
        
        set date = `date +%Y%m%d`
        set base = /apps/dpr2/apps/ui/atom
        
        cd /dpr2/apps/ui/current
        
        # Nuxeo Collection
        #    Atom URL: <%= feed_url %>
        #
        # Merritt Collection
        #    Collection ID: <%= collection_ark %>
        #    Name: <%= collection_name %>
        #    Mnemonic: <%= collection_mnemonic %>
        
        # To pause, uncomment...
        #touch PAUSE_ATOM_<%= collection_mnemonic %>_content
        
        # Last feed update, defined in atom.ldap
        # /dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_<%= collection_ark_qualifier %>
        
        set feedURL	= "<%= feed_url %>"
        set userAgent	= "Atom processor/<%= collection_name %>"
        set profile	= "<%= collection_mnemonic %>_content"
        set collection	= "<%= collection_ark_qualifier %>"         # feed collection
        set groupID	= "<%= collection_ark %>"
        # Was defined in atom.yml file, but now here
        set updateFile	= "/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_${collection}"
        set log		= "${base}/logs/${profile}_${date}.log"
        
        # Log file
        bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &
        
        # No log file
        # bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"
        
        exit
      ERB

      class << self

        def template
          @template ||= ERB.new(CSH_TEMPLATE)
        end

        # noinspection RubyUnusedLocalVariable
        def generate_csh(feed_url:, collection_mnemonic:, collection_ark:, collection_name:)
          collection_ark_qualifier = collection_ark.scan(ARK_QUALIFIER_REGEXP).first
          opts = OpenStruct.new(
            feed_url: feed_url,
            collection_mnemonic: collection_mnemonic,
            collection_ark: collection_ark,
            collection_name: collection_name,
          )
          template.result(binding)
        end

        def from_csv(csv_data:, to_dir:)
          CSV.parse(csv_data) do |row|
            feed_url, collection_mnemonic, collection_ark, collection_name = row
            csh = generate_csh(feed_url: feed_url, collection_mnemonic: collection_mnemonic, collection_ark: collection_ark, collection_name: collection_name)
            File.open(File.join(to_dir, "#{collection_mnemonic}.csh"), 'w') { |f| f.write(csh) }
          end
        end

      end
    end
  end
end