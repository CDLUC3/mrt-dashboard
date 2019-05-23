require 'spec_helper'

require 'merritt/atom'

module Merritt
  module Atom
    describe CSHGenerator do
      describe :generate_csh do
        it 'generates a CSH script' do
          expected_csh = <<~CSH
            # setenv RAILS_ENV stage
            setenv PATH /dpr2/local/bin:${PATH}
            
            set date = `date +%Y%m%d`
            set base = /apps/dpr2/apps/ui/atom
            
            cd /dpr2/apps/ui/current
            
            # Nuxeo Collection
            #    Atom URL: https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom
            #
            # Merritt Collection
            #    Collection ID: ark:/13030/m5b58sn8
            #    Name: Merced Library Nuxeo collection
            #    Mnemonic: ucm_lib_nuxeo
            
            # To pause, uncomment...
            #touch PAUSE_ATOM_ucm_lib_nuxeo_content
            
            # Last feed update, defined in atom.ldap
            # /dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_m5b58sn8
            
            set feedURL	= "https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom"
            set userAgent	= "Atom processor/Merced Library Nuxeo collection"
            set profile	= "ucm_lib_nuxeo_content"
            set collection	= "m5b58sn8"         # feed collection
            set groupID	= "ark:/13030/m5b58sn8"
            # Was defined in atom.yml file, but now here
            set updateFile	= "/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_${collection}"
            set log		= "${base}/logs/${profile}_${date}.log"
            
            # Log file
            bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &
            
            # No log file
            # bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"
            
            exit
          CSH

          actual_csh = CSHGenerator.generate_csh(
            feed_url: 'https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom',
            collection_ark: 'ark:/13030/m5b58sn8',
            collection_name: 'Merced Library Nuxeo collection',
            collection_mnemonic: 'ucm_lib_nuxeo'
          )

          File.open('tmp/expected.csh', 'w') { |f| f.write(expected_csh) }
          File.open('tmp/actual.csh', 'w') { |f| f.write(actual_csh) }

          expect(actual_csh).to eq(expected_csh)
        end
      end

      describe :from_csh do
        it 'generates a file for each entry' do
          csv_data = <<~CSV
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27014.atom,ucm_lib_ucce_humboldt,ark:/13030/m590717c,UC Merced Library UCCE Humboldt County
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27013.atom,ucm_lib_ucce_ventura,ark:/13030/m5dr7rw3,UC Merced Library UCCE Ventura County
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27012.atom,ucm_lib_ucce_merced,ark:/13030/m5jh8hmt,UC Merced Library UCCE Merced County
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_65.atom,ucm_lib_clark,ark:/13030/m5n58jd1,UCM Library Clark Center for Japanese Art and Culture
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_68.atom,ucm_lib_mclean,ark:/13030/m5p89893,UC Merced Library McLean Collection
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_14256.atom,ucm_lib_mcdaniel,ark:/13030/m5t20138,UC Merced Library McDaniel (Wilma E.) Papers
            https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_69.atom,ucm_lib_acm,ark:/13030/m5xq22b2,UC Merced Library Angels Camp Museum
          CSV

          Dir.mktmpdir do |tmpdir|
            CSHGenerator.from_csv(csv_data: csv_data, to_dir: tmpdir)
            files = Dir.entries(tmpdir)
                      .map { |f| File.join(tmpdir, f) }
                      .select { |f| File.file?(f) }
            CSV.parse(csv_data) do |row|
              feed_url, collection_mnemonic, collection_ark, collection_name = row
              expected_file = File.join(tmpdir, "#{collection_mnemonic}.csh")
              expect(files).to include(expected_file)
              expected_data = CSHGenerator.generate_csh(feed_url: feed_url, collection_mnemonic: collection_mnemonic, collection_ark: collection_ark, collection_name: collection_name)
              actual_data = File.read(expected_file)
              expect(actual_data).to eq(expected_data)
            end
            expect(files.size).to eq(7)
          end
        end
      end
    end
  end
end
