require 'rails_helper'
require 'support/tasks'
require 'webmock/rspec'
require 'fileutils'

describe 'atom', type: :task do

  before(:each) do
    WebMock.disable_net_connect!
  end

  after(:each) do
    WebMock.allow_net_connect!
  end

  it 'is configured' do
    expect(APP_CONFIG['ingest_service']).not_to be_nil
  end

  context ':update' do
    attr_reader :feed_xml_str
    attr_reader :feed_xml

    attr_reader :original_home
    attr_reader :tmp_home

    attr_reader :client
    attr_reader :server

    attr_reader :starting_point
    attr_reader :submitter
    attr_reader :profile
    attr_reader :collection
    attr_reader :collection_ark
    attr_reader :feeddatefile

    attr_reader :pause_file

    def atom_dir
      "#{tmp_home}/dpr2/apps/ui/atom/"
    end

    def write_feeddate(date)
      FileUtils.mkdir_p(File.dirname(feeddatefile))
      open(feeddatefile, 'w') { |f| f.puts(date.utc.iso8601) }
    end

    def invoke_update!
      invoke_task('atom:update', starting_point, submitter, profile, collection, feeddatefile)
    end

    def add_file
      tmpfile = Tempfile.new
      @tempfiles << tmpfile
      File.open(tmpfile, 'w+') { |f| yield f }
      ["http://ingest.example.edu/#{File.basename(tmpfile)}", tmpfile]
    end

    before(:each) do
      @feed_xml_str = File.read('spec/data/ucldc_collection_5551212.atom').freeze
      @feed_xml = Nokogiri::XML(feed_xml_str)

      @original_home = ENV['HOME']
      @tmp_home = Dir.mktmpdir
      ENV['HOME'] = @tmp_home

      @client = instance_double(Mrt::Ingest::Client)
      allow(Mrt::Ingest::Client).to receive(:new).with(APP_CONFIG['ingest_service']).and_return(client)
      allow(client).to receive(:ingest)

      @server = instance_double(Mrt::Ingest::OneTimeServer)
      allow(Mrt::Ingest::OneTimeServer).to receive(:new).and_return(server)
      allow(server).to receive(:start_server)
      allow(server).to receive(:join_server)
      allow(server).to(receive(:add_file).with(no_args)) { |&block| add_file(&block) }

      @starting_point = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_26144.atom'
      @submitter = 'Atom processor/Example U Digital Special Collections'
      @profile = 'example_ingest_profile'
      @collection = 'FK5551212'
      @collection_ark = "ark:/99999/#{collection}"
      @feeddatefile = "#{tmp_home}/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
      write_feeddate(Time.now)

      @pause_file = "#{atom_dir}/PAUSE_ATOM_#{profile}"

      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      @tempfiles = []
    end

    after(:each) do
      ENV['HOME'] = original_home
      FileUtils.remove_entry_secure(@tmp_home)
      @tempfiles.each { |f| FileUtils.remove_entry_secure(f) }
    end

    it 'starts the one-time file server' do
      expect(server).to receive(:start_server)
      invoke_update!
    end

    it 'sleeps if pause file is present' do
      FileUtils.mkdir_p(atom_dir)
      FileUtils.touch(pause_file)

      # HACK: to "expect().to receive" global sleep call
      @sleep_count = 0
      allow_any_instance_of(Object).to receive(:sleep).with(300) do
        @sleep_count += 1
        FileUtils.remove_entry_secure(pause_file)
      end

      invoke_update!
      expect(@sleep_count).to eq(1)
    end

    it 'doesn\'t sleep if pause file not present' do
      expect(File.exist?(pause_file)).to be_falsey # just to be sure

      # HACK: to "expect().not_to receive" global sleep call
      @sleep_count = 0
      allow_any_instance_of(Object).to receive(:sleep).with(300) do
        @sleep_count += 1
        FileUtils.remove_entry_secure(pause_file)
      end

      invoke_update!
      expect(@sleep_count).to eq(0)
    end

    # TODO: fix code, then re-enable this test
    skip 'exits without trying to parse if request returns 404' do
      stub_request(:get, starting_point).to_return(status: [404, 'Not Found'])
      expect(Nokogiri).not_to receive(:XML)
      invoke_update!
    end

    # TODO: fix code, then re-enable this test
    skip 'writes new feed date file and exits if feed date file not found' do
      FileUtils.remove_entry_secure(feeddatefile)
      expect(Mrt::Ingest::IObject).not_to receive(:new)
      invoke_update!
    end

    it 'exits without updating if feed not updated since last harvest' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated + 1) # +1 day
      expect(Mrt::Ingest::IObject).not_to receive(:new)
      invoke_update!
    end

    it 'updates if feed updated since last harvest' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      expect(server).to receive(:add_file).exactly(2).times
      expect(client).to receive(:ingest).exactly(2).times

      invoke_update!
    end

    it 'stages the ERC kernel metadata via the one-time server' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      invoke_update!

      expected0 = <<~TMP0
        erc:
        who: Merced County Sheriff's Office
        what: Merced County Sheriff's Office mug book
        when: 1885-19--?
        where:
        when/created:
        when/modified: 2015-08-20T19:06:37.622000+00:00
      TMP0

      expected1 = <<~TMP1
        erc:
        who:
        what: Merced Army Flying School
        when: 194-?
        where:
        when/created:
        when/modified: 2015-05-29T18:01:40.927000+00:00
      TMP1

      expected = [
        # Mrt::Ingest::IObject leaves trailing spaces when value is nil
        expected0.gsub(/^(w[^:]+):\n/, "\\1: \n"),
        expected1.gsub(/^(w[^:]+):\n/, "\\1: \n"),
      ]

      temp_contents = @tempfiles.map { |f| File.read(f) }
      expect(temp_contents).to eq(expected)
    end

    it 'correctly populates the ingest request' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      request_args = []
      allow(client).to(receive(:ingest)) { |request| request_args << request.mk_args }

      invoke_update!

      expect(request_args.size).to eq(2)
      files = request_args.map { |ra| ra['file'] }
      # TODO: test file contents

      expected_args = [
        {
          'file' => files[0],
          'filename' => File.basename(files[0]),
          'localIdentifier' => '494672cf-2937-4975-8b33-90bf80b4c8a6',
          'profile' => 'example_ingest_profile',
          'responseForm' => 'json',
          'submitter' => 'Atom processor/Example U Digital Special Collections',
          'type' => 'object-manifest'
        },
        {
          'file' => files[1],
          'filename' => File.basename(files[1]),
          'localIdentifier' => '365579cc-a369-45e7-8977-047bda3f7ed1',
          'profile' => 'example_ingest_profile',
          'responseForm' => 'json',
          'submitter' => 'Atom processor/Example U Digital Special Collections',
          'type' => 'object-manifest'
        }
      ]
      expect(request_args).to eq(expected_args)
    end

    # TODO: make this happen
    pending 'exits with an error if ATOM_CONFIG does not include collection credentials'
    pending 'exits with an error if ATOM_CONFIG does not include local ID element'

    pending 'stops paginating when next page is nil'
    pending 'doesn\'t update if initial feed is nil'

    pending 'requires a submitter'
    pending 'requires a profile'
    pending 'requires a collection ARK'
    pending 'requires a feeddatefile'
    pending 'requires a starting_point'

    it 'waits for the one-time file server to exit' do
      expect(server).to receive(:join_server)
      invoke_update!
    end
  end
end
