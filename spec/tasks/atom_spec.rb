require 'rails_helper'
require 'support/tasks'
require 'webmock/rspec'
require 'fileutils'

describe 'atom', type: :task do
  before(:each) do
    WebMock.disable_net_connect!
  end

  it 'is configured' do
    expect(APP_CONFIG['ingest_service']).not_to be_nil
  end

  context ':update' do
    attr_reader :original_home
    attr_reader :tmp_home

    attr_reader :client
    attr_reader :server

    attr_reader :starting_point
    attr_reader :submitter
    attr_reader :profile
    attr_reader :collection
    attr_reader :feeddatefile

    before(:each) do
      @original_home = ENV['HOME']
      @tmp_home = Dir.mktmpdir
      ENV['HOME'] = @tmp_home

      @client = instance_double(Mrt::Ingest::Client)
      allow(Mrt::Ingest::Client).to receive(:new).with(APP_CONFIG['ingest_service']).and_return(client)

      @server = instance_double(Mrt::Ingest::OneTimeServer)

      @starting_point = 'https://example.edu/merritt/feed.atom'
      @profile = 'example_ingest_profile'
      @collection = 'ark:/99999/FK5551212'
      @feeddatefile = "/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
    end

    after(:each) do
      ENV['HOME'] = original_home
      FileUtils.remove_entry_secure(@tmp_home)
    end

    def atom_dir
      "#{tmp_home}/dpr2/apps/ui/atom/"
    end

    skip 'starts the server' do
      expect(server).to receive(:start_server)
      invoke_task('atom:update', starting_point, submitter, profile, collection, feeddatefile)
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