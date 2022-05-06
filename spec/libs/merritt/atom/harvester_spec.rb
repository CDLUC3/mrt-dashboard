require 'rails_helper'
require 'webmock/rspec'
require 'merritt/atom'

module Merritt
  module Atom
    describe Harvester do

      # ------------------------------------------------------------
      # Fixture

      attr_reader :original_home
      attr_reader :tmp_home
      attr_reader :atom_dir
      attr_reader :args
      attr_reader :page_client

      attr_reader :one_time_server
      attr_reader :ingest_client

      before(:each) do
        WebMock.disable_net_connect!

        # HACK: to "expect().to receive" global sleep call
        @sleep_count = 0
        allow_any_instance_of(Object).to(receive(:sleep).with(DEFAULT_DELAY)) { @sleep_count += 1 }

        @original_home = ENV.fetch('HOME', nil)
        @tmp_home = Dir.mktmpdir
        ENV['HOME'] = @tmp_home

        @atom_dir = "#{tmp_home}/dpr2/apps/ui/atom/"
        FileUtils.mkdir_p(atom_dir)

        collection = 'FK5551212'

        feed_update_file = "#{tmp_home}/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
        FileUtils.mkdir_p(File.dirname(feed_update_file))
        File.open(feed_update_file, 'w') { |f| f.puts(Util::NEVER) }

        @args = {
          starting_point: 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_26144.atom',
          submitter: 'Atom processor/Example U Digital Special Collections',
          profile: 'example_ingest_profile',
          collection_ark: "ark:/99999/#{collection}",
          feed_update_file: feed_update_file,
          delay: 123,
          batch_size: 10
        }

        @page_client = instance_double(PageClient)
        allow(PageClient).to receive(:new).and_return(page_client)

        @one_time_server = instance_double(Mrt::Ingest::OneTimeServer)
        allow(Mrt::Ingest::OneTimeServer).to receive(:new).and_return(one_time_server)
        allow(one_time_server).to receive(:start_server)
        allow(one_time_server).to receive(:join_server)

        @ingest_client = instance_double(Mrt::Ingest::Client)
        allow(Mrt::Ingest::Client).to receive(:new).with(APP_CONFIG['ingest_service']).and_return(ingest_client)
        allow(ingest_client).to receive(:ingest)
      end

      after(:each) do
        ENV['HOME'] = original_home
        WebMock.allow_net_connect!
        FileUtils.remove_entry_secure(tmp_home)
      end

      # ------------------------------------------------------------
      # Tests

      it 'processes the first page' do
        harvester = Harvester.new(args)
        expect(page_client).to receive(:process_page!).and_return(nil)
        harvester.process_feed!
      end

      it 'processes all pages' do
        page_urls = (1..5).map { |i| "http://example.org/feed/#{i}.atom" }

        @args[:starting_point] = page_urls[0]
        harvester = Harvester.new(args)
        page_urls.each_with_index do |page_url, i|
          pp = instance_double(PageClient)
          expect(PageClient).to receive(:new)
            .with(page_url: page_url, harvester: harvester)
            .ordered
            .and_return(pp)
          next_page = i + 1 < page_urls.length ? page_urls[i + 1] : nil
          result = PageResult.new(atom_updated: Time.now.iso8601, next_page: next_page)
          expect(pp).to receive(:process_page!).and_return(result)
        end
        harvester.process_feed!
      end

      it 'pauses if pause file is present' do
        expected_delay = args[:delay]

        pause_file_path = "#{atom_dir}/PAUSE_ATOM_#{args[:profile]}"
        FileUtils.touch(pause_file_path)

        # HACK: to "expect().to receive" global sleep call
        allow_any_instance_of(Object).to receive(:sleep).with(expected_delay) do
          @sleep_count += 1
          FileUtils.remove_entry_secure(pause_file_path)
        end

        harvester = Harvester.new(args)
        expect(page_client).to receive(:process_page!)
        harvester.process_feed!
      end

      it 'joins the server' do
        expect(one_time_server).to receive(:join_server)
        harvester = Harvester.new(args)
        harvester.send(:one_time_server) # make sure it's initialized
        allow(page_client).to receive(:process_page!).and_return(nil)
        harvester.process_feed!
      end

      it 'joins the server even in the event of an error' do
        expect(one_time_server).to receive(:join_server)
        harvester = Harvester.new(args)
        harvester.send(:one_time_server) # make sure it's initialized
        allow(page_client).to receive(:process_page!).and_raise('Oops')
        expect { harvester.process_feed! }.to raise_error('Oops')
      end

      it 'logs an error if server can\'t be joined' do
        expect(one_time_server).to receive(:join_server).and_raise('Oops')
        expect(Rails.logger).to receive(:error).with(/Oops/)

        harvester = Harvester.new(args)
        harvester.send(:one_time_server) # make sure it's initialized
        allow(page_client).to receive(:process_page!).and_return(nil)
        harvester.process_feed!
      end
    end
  end
end
