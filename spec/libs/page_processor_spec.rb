require 'rails_helper'
require 'webmock/rspec'
require 'merritt/atom'

module Merritt
  module Atom
    describe PageProcessor do

      attr_reader :feed_processor

      before(:each) do
        WebMock.disable_net_connect!

        @feed_processor = instance_double(FeedProcessor)
      end

      after(:each) do
        WebMock.allow_net_connect!
      end

      it 'gets the next page' do
        page1_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-1.atom'
        page1_path = 'spec/data/ucldc_collection_9585555-1.atom'
        stub_request(:get, page1_url).to_return(status: 200, body: File.new(page1_path), headers: {})

        page_processor = PageProcessor.new(page_url: page1_url, feed_processor: feed_processor)
        next_page = page_processor.process_page!
        page2_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-2.atom'
        expect(next_page).to eq(page2_url)
      end
      
      it 'returns nil if no next page' do
        page3_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-3.atom'
        page3_path = 'spec/data/ucldc_collection_9585555-3.atom'
        stub_request(:get, page3_url).to_return(status: 200, body: File.new(page3_path), headers: {})

        page_processor = PageProcessor.new(page_url: page3_url, feed_processor: feed_processor)
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
          expect(feed_processor).to receive(:log_error).with("Error processing page #{page1_url} (tries = #{t})", RestClient::InternalServerError).ordered
        end

        page_processor = PageProcessor.new(page_url: page1_url, feed_processor: feed_processor)
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
          expect(feed_processor).to receive(:log_error).with("Error processing page #{page1_url} (tries = #{t})", RestClient::InternalServerError).ordered
        end

        page_processor = PageProcessor.new(page_url: page1_url, feed_processor: feed_processor)
        next_page = page_processor.process_page!
        expect(next_page).to be_nil
        expect(@try).to eq(3)
      end
    end
  end
end