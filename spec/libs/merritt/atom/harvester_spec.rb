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

      it 'get last_feed_update' do
        harvester = Harvester.new(args)
        expect(harvester.last_feed_update).not_to be_nil
      end

      it 'test harvester.new_ingest_object' do
        harvester = Harvester.new(args)
        ingest_object = harvester.new_ingest_object(
          local_id: "local",
          erc_who: "who",
          erc_what: "what",
          erc_when: "when",
          erc_where: "where",
          erc_when_created: "2022-01-01",
          erc_when_modified: "2022-01-01"
        )
        uri = URI.parse("https://nuxeo.cdlib.org/Nuxeo/nxdoc/default/133be0f7-99b2-4e88-8842-d247993d7bac/view_documents")
        harvester.add_credentials!(uri)
        harvester.start_ingest(ingest_object)
      end
    end

  end
end
