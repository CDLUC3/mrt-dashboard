require 'rails_helper'
require 'support/tasks'
require 'webmock/rspec'
require 'fileutils'

def invoke_update!
  invoke_task('atom:update', starting_point, submitter, profile, collection, feeddatefile)
end

describe 'atom', type: :task do

  before(:each) do
    WebMock.disable_net_connect!
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

    def atom_dir
      "#{tmp_home}/dpr2/apps/ui/atom/"
    end

    def write_feeddate(date)
      FileUtils.mkdir_p(File.dirname(feeddatefile))
      open(feeddatefile, 'w') { |f| f.puts(date.utc.iso8601)}
    end

    before(:each) do
      @feed_xml_str = File.read('spec/data/ucldc_collection_5551212.atom').freeze
      @feed_xml = Nokogiri::XML(feed_xml_str)

      @original_home = ENV['HOME']
      @tmp_home = Dir.mktmpdir
      ENV['HOME'] = @tmp_home

      @client = instance_double(Mrt::Ingest::Client)
      allow(Mrt::Ingest::Client).to receive(:new).with(APP_CONFIG['ingest_service']).and_return(client)

      @server = instance_double(Mrt::Ingest::OneTimeServer)
      allow(Mrt::Ingest::OneTimeServer).to receive(:new).and_return(server)
      allow(server).to receive(:start_server)
      allow(server).to receive(:join_server)

      @starting_point = 'https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_26144.atom'
      @profile = 'example_ingest_profile'
      @collection = 'FK5551212'
      @collection_ark = "ark:/99999/#{collection}"
      @feeddatefile = "#{tmp_home}/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
      write_feeddate(Time.now)

      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})
    end

    after(:each) do
      ENV['HOME'] = original_home
      FileUtils.remove_entry_secure(@tmp_home)
    end

    it 'starts the one-time file server' do
      expect(server).to receive(:start_server)
      invoke_update!
    end

    it 'waits for the one-time file server to exit' do
      expect(server).to receive(:join_server)
      invoke_update!
    end

    it 'exits without updating if feed not updated since last harvest' do
      feed_updated = DateTime.parse(feed_xml.at_xpath("//xmlns:updated").text)
      write_feeddate(feed_updated + 1) # +1 day
      expect(Mrt::Ingest::IObject).not_to receive(:new)
      invoke_update!
    end

    skip 'updates if feed updated since last harvest' do
      feed_updated = DateTime.parse(feed_xml.at_xpath("//xmlns:updated").text)
      write_feeddate(feed_updated - 1) # -1 day
    end
    
    skip 'sleeps if pause file is present' do
      FileUtils.mkdir_p(atom_dir)
      pause_file = "#{atom_dir}/PAUSE_ATOM_#{profile}"
      FileUtils.touch(pause_file)

      fail("not implemented")
    end

    pending 'requires a submitter'
    pending 'requires a profile'
    pending 'requires a collection ARK'
    pending 'requires a feeddatefile'
    pending 'requires a starting_point'

  end
end