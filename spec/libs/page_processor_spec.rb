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
        next_page = page_processor.process
        page2_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-2.atom'
        expect(next_page).to eq(page2_url)
      end
      
      it 'returns nil if no next page' do
        page3_url = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-3.atom'
        page3_path = 'spec/data/ucldc_collection_9585555-3.atom'
        stub_request(:get, page3_url).to_return(status: 200, body: File.new(page3_path), headers: {})
        page_processor = PageProcessor.new(page_url: page3_url, feed_processor: feed_processor)
        next_page = page_processor.process
        expect(next_page).to be_nil
      end
    end
  end
end