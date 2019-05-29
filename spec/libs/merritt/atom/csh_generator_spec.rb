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
            #    Registry ID: 26098
            #    Name: UCM Ramicova
            #
            # Merritt Collection
            #    Collection ID: ark:/13030/m5b58sn8
            #    Name: Merced Library Nuxeo collection
            #    Mnemonic: ucm_lib_nuxeo

            # To pause, uncomment...
            #touch PAUSE_ATOM_ucm_lib_nuxeo_content

            # Last feed update, defined in atom.ldap
            # /dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_26098-m5b58sn8

            set feedURL	= "https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom"
            set userAgent	= "Atom processor/Merced Library Nuxeo collection"
            set profile	= "ucm_lib_nuxeo_content"
            set groupID	= "ark:/13030/m5b58sn8"
            set updateFile	= "/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_26098-m5b58sn8"
            set log		= "${base}/logs/${profile}_${date}.log"

            # Log file
            bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

            # No log file
            # bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

            exit
          CSH

          actual_csh = CSHGenerator.generate_csh(
            nuxeo_collection_name: 'UCM Ramicova',
            feed_url: 'https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom',
            merritt_collection_mnemonic: 'ucm_lib_nuxeo',
            merritt_collection_ark: 'ark:/13030/m5b58sn8',
            merritt_collection_name: 'Merced Library Nuxeo collection'
          )

          File.open('tmp/expected.csh', 'w') { |f| f.write(expected_csh) }
          File.open('tmp/actual.csh', 'w') { |f| f.write(actual_csh) }

          expect(actual_csh).to eq(expected_csh)
        end
      end

      describe :sanitize_name do
        it 'sanitizes names' do
          names = {
            'Raebel, Hermann C. Papers' => 'Raebel-Hermann-C-Papers',
            'UCCE Merced' => 'UCCE-Merced',
            'LIJA/Clark Center' => 'LIJA-Clark-Center',
            'McLean' => 'McLean',
            'Angel’s Camp' => 'Angels-Camp',
            'Miriam Matthews Photograph Collection' => 'Miriam-Matthews-Photograph-Collection',
            '' => ''
          }
          names.each do |original, expected|
            actual = CSHGenerator.sanitize_name(original)
            expect(actual).to eq(expected)
          end
        end
      end

      describe :from_csh do
        it 'generates a file for each entry' do
          csv_data = <<~CSV
            UCCE Humboldt,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27014.atom,ucm_lib_ucce_humboldt,ark:/13030/m590717c,UC Merced Library UCCE Humboldt County,
            UCCE Ventura,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27013.atom,ucm_lib_ucce_ventura,ark:/13030/m5dr7rw3,UC Merced Library UCCE Ventura County,
            UCCE Merced,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_27012.atom,ucm_lib_ucce_merced,ark:/13030/m5jh8hmt,UC Merced Library UCCE Merced County,
            LIJA/Clark Center,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_65.atom,ucm_lib_clark,ark:/13030/m5n58jd1,UCM Library Clark Center for Japanese Art and Culture,Also exists on stage
            McLean,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_68.atom,ucm_lib_mclean,ark:/13030/m5p89893,UC Merced Library McLean Collection,
            McDaniel,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_14256.atom,ucm_lib_mcdaniel,ark:/13030/m5t20138,UC Merced Library McDaniel (Wilma E.) Papers,
            Angel’s Camp,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_69.atom,ucm_lib_acm,ark:/13030/m5xq22b2,UC Merced Library Angels Camp Museum,
            "Raebel, Hermann C. Papers",https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26899.atom,ucla_digital_lib,ark:/13030/m5k40smm,UCLA Digital Library Program,"Exists on stage only, for the UCLA pilot"
            Miriam Matthews Photograph Collection,https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26936.atom,ucla_digital_lib,ark:/13030/m5k40smm,UCLA Digital Library Program,"Exists on stage only, for the UCLA pilot"
          CSV

          expected_files = %w[
            27014-UCCE-Humboldt-ucm_lib_ucce_humboldt.csh
            27013-UCCE-Ventura-ucm_lib_ucce_ventura.csh
            27012-UCCE-Merced-ucm_lib_ucce_merced.csh
            65-LIJA-Clark-Center-ucm_lib_clark.csh
            68-McLean-ucm_lib_mclean.csh
            14256-McDaniel-ucm_lib_mcdaniel.csh
            69-Angels-Camp-ucm_lib_acm.csh
            26899-Raebel-Hermann-C-Papers-ucla_digital_lib.csh
            26936-Miriam-Matthews-Photograph-Collection-ucla_digital_lib.csh
          ]

          Dir.mktmpdir do |tmpdir|
            CSHGenerator.from_csv(csv_data: csv_data, to_dir: tmpdir)
            files = Dir.entries(tmpdir)
              .map { |f| File.join(tmpdir, f) }
              .select { |f| File.file?(f) }
            index = 0
            CSV.parse(csv_data) do |row|
              nuxeo_collection_name, feed_url, collection_mnemonic, collection_ark, merritt_collection_name = row[0...5]
              expected_file = File.join(tmpdir, expected_files[index])
              expect(files).to include(expected_file)
              expected_data = CSHGenerator.generate_csh(
                nuxeo_collection_name: nuxeo_collection_name,
                feed_url: feed_url,
                merritt_collection_mnemonic: collection_mnemonic,
                merritt_collection_ark: collection_ark,
                merritt_collection_name: merritt_collection_name
              )
              actual_data = File.read(expected_file)
              expect(actual_data).to eq(expected_data)
              index += 1
            end
            expect(files.size).to eq(expected_files.size)
          end
        end
      end
    end
  end
end
