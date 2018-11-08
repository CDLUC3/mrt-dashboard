require 'rails_helper'
require 'webmock/rspec'
require 'merritt/atom'

module Merritt
  module Atom
    describe PageClient do

      attr_reader :harvester
      attr_reader :feed_processor

      before(:each) do
        WebMock.disable_net_connect!
        @harvester = instance_double(Harvester)
        allow(harvester).to receive(:last_feed_update).and_return(Util::NEVER)
        allow(harvester).to receive(:local_id_query).and_return('dc:identifier')
        allow(harvester).to receive(:add_credentials!)
      end

      after(:each) do
        WebMock.allow_net_connect!
      end

      it 'gets the next page' do
        page1_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-1.atom'
        page1_path = 'spec/data/ucldc_collection_9585555-1.atom'
        stub_request(:get, page1_url).to_return(status: 200, body: File.new(page1_path), headers: {})

        3.times do
          ingest_obj = instance_double(Mrt::Ingest::IObject)
          allow(ingest_obj).to receive(:add_component)
          expect(harvester).to receive(:new_ingest_object).and_return(ingest_obj).ordered
          expect(harvester).to receive(:start_ingest).with(ingest_obj).ordered
          allow(ingest_obj).to receive(:add_component)
        end

        page_processor = PageClient.new(page_url: page1_url, harvester: harvester)
        next_page = page_processor.process_page!
        page2_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-2.atom'
        expect(next_page).to eq(page2_url)
      end

      it 'returns nil if no next page' do
        page3_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-3.atom'
        page3_path = 'spec/data/ucldc_collection_9585555-3.atom'
        stub_request(:get, page3_url).to_return(status: 200, body: File.new(page3_path), headers: {})

        ingest_obj = instance_double(Mrt::Ingest::IObject)
        allow(ingest_obj).to receive(:add_component)
        allow(harvester).to receive(:new_ingest_object).and_return(ingest_obj)
        allow(harvester).to receive(:start_ingest).with(ingest_obj)

        page_processor = PageClient.new(page_url: page3_url, harvester: harvester)
        next_page = page_processor.process_page!
        expect(next_page).to be_nil
      end

      it 'retries three times in the event of an error' do
        page1_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-1.atom'
        page1_path = 'spec/data/ucldc_collection_9585555-1.atom'

        @try = 0
        stub_request(:get, page1_url).to_return do |_|
          @try += 1
          if @try != 3
            { status: 500, body: 'Oops, try again!', headers: {} }
          else
            { status: 200, body: File.new(page1_path), headers: {} }
          end
        end

        (1..2).each do |t|
          expect(Rails.logger).to receive(:error).with(/Error processing page #{page1_url} \(tries = #{t}\): 500 Internal Server Error/).ordered
        end

        3.times do
          ingest_obj = instance_double(Mrt::Ingest::IObject)
          allow(ingest_obj).to receive(:add_component)
          expect(harvester).to receive(:new_ingest_object).and_return(ingest_obj).ordered
          expect(harvester).to receive(:start_ingest).with(ingest_obj).ordered
        end

        page_processor = PageClient.new(page_url: page1_url, harvester: harvester)
        next_page = page_processor.process_page!
        page2_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-2.atom'
        expect(next_page).to eq(page2_url)
        expect(@try).to eq(3) # just to be sure
      end

      it 'gives up after the third failure' do
        page1_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-1.atom'

        @try = 0
        stub_request(:get, page1_url).to_return do |_|
          @try += 1
          { status: 500, body: 'Oops, try again!', headers: {} }
        end

        (1..3).each do |t|
          expect(Rails.logger).to receive(:error).with(/Error processing page #{page1_url} \(tries = #{t}\): 500 Internal Server Error/).ordered
        end

        expect(harvester).not_to receive(:new_ingest_object)

        page_processor = PageClient.new(page_url: page1_url, harvester: harvester)
        next_page = page_processor.process_page!
        expect(next_page).to be_nil
        expect(@try).to eq(3)
      end
    end
  end
end
