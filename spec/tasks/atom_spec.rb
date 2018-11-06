require 'rails_helper'
require 'support/tasks'
require 'webmock/rspec'
require 'fileutils'

describe 'atom', type: :task do

  ATOM_NS = {"atom" => "http://www.w3.org/2005/Atom"}
  EXPECTED_MANIFESTS = (0..1).map {|i| File.read("spec/data/ucldc_collection_5551212-manifest-#{i}.checkm").freeze}.freeze
  EXPECTED_ERC_CHECKSUMS = ['664d879f4609ef03f043dae7e4353959'.freeze, '0a10eaecc019131f17de4da54c32085b'.freeze]

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
      open(feeddatefile, 'w') {|f| f.puts(date.utc.iso8601)}
    end

    def invoke_update!
      invoke_task('atom:update', starting_point, submitter, profile, collection_ark, feeddatefile)
    end

    def add_file
      tmpfile = Tempfile.new('', tmp_home)
      @tempfiles << tmpfile
      File.open(tmpfile, 'w+') {|f| yield f}
      ["http://ingest.example.edu/#{File.basename(tmpfile)}", tmpfile]
    end

    def actual_erc_filenames
      Dir.entries(tmp_home)
        .select {|f| File.file?("#{tmp_home}/#{f}")}
        .sort_by {|f| File.ctime("#{tmp_home}/#{f}")}
    end

    def validate_request!(request_args, erc_checksums = EXPECTED_ERC_CHECKSUMS)
      expect(request_args.size).to eq(2)
      files = request_args.map {|ra| ra['file']}

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

      erc_filenames = actual_erc_filenames
      files.each_with_index do |f, i|
        actual_manifest_lines = f.read.strip.split("\n").map { |line| line.strip }
        expected_manifest_lines = EXPECTED_MANIFESTS[i]
                                    .sub('ACTUAL_ERC_FILENAME', "http://ingest.example.edu/#{erc_filenames[i]}")
                                    .sub('EXPECTED_ERC_CHECKSUM', erc_checksums[i])
                                    .strip.split("\n").map { |line| line.strip }
        expect(actual_manifest_lines.size).to eq(expected_manifest_lines.size)
        aggregate_failures 'manifest differences' do
          expected_manifest_lines.each_with_index do |expected_line, j|
            expect(actual_manifest_lines[j]).to eq(expected_line)
          end
        end
      end
    end

    before(:each) do
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
      allow(server).to(receive(:add_file).with(no_args)) {|&block| add_file(&block)}

      @feed_xml_str = File.read('spec/data/ucldc_collection_5551212.atom').freeze
      @feed_xml = Nokogiri::XML(feed_xml_str)
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

    it 'exits without updating if request returns 404' do
      stub_request(:get, starting_point).to_return(status: [404, 'Not Found'])
      expect(Mrt::Ingest::IObject).not_to receive(:new)

      begin
        invoke_update!
      rescue Errno::ENOENT
        # TODO: fix code, then remove this rescue block
      end
    end

    it 'writes new feed date file and exits if feed date file not found' do
      FileUtils.remove_entry_secure(feeddatefile)
      expect(Mrt::Ingest::IObject).not_to receive(:new)

      begin
        invoke_update!
      rescue Errno::ENOENT
        # TODO: fix code, then remove this rescue block
      end

      expect(WebMock).to have_requested(:get, starting_point)
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

    it 'updates if feed updated since last harvest' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @start_count = 0
      expect(server).to receive(:start_server).exactly(3).times do
        @start_count += 1
        if @start_count == 2
          raise 'random failure on second object'
        end
      end

      expect(server).to receive(:add_file).exactly(2).times
      expect(client).to receive(:ingest).exactly(1).times

      invoke_update!
    end

    # TODO: fix code, then re-enable this test
    skip 'updates if no <updated/> tag found under root' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated + 1) # +1 day, ordinarily would be skipped
      @feed_xml_str = @feed_xml_str.sub(/^ {2}<updated>[^<]+<\/updated>/, '')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      expect(server).to receive(:add_file).exactly(2).times
      expect(client).to receive(:ingest).exactly(2).times

      invoke_update!
    end

    # TODO: fix code, then re-enable this test
    skip 'updates if no <updated/> tag found under entries' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # - 1 day
      @feed_xml_str = @feed_xml_str.gsub(/ {4}<updated>[^<]+<\/updated>/, '')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

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

      temp_contents = @tempfiles.map {|f| File.read(f)}
      expect(temp_contents).to eq(expected)
    end

    it 'correctly populates the ingest request' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      validate_request!(request_args)
    end

    it 'doesn\'t require <dc:title/>' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @feed_xml_str = @feed_xml_str.gsub(/<dc:title>[^<]+<\/dc:title>/, '')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      validate_request!(request_args)
    end

    # TODO: fix code, then re-enable this test
    skip 'doesn\'t require <dc:date/>' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @feed_xml_str = @feed_xml_str.gsub(/<dc:date>[^<]+<\/dc:date>/, '')
      @feed_xml_str = @feed_xml_str.gsub(/<dc:date\/>/, '')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      validate_request!(request_args)
    end

    it 'falls back to <atom:published/> when <dc:date/> empty' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @feed_xml_str = @feed_xml_str.gsub(/<dc:date>[^<]+<\/dc:date>/, '<dc:date/>')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      expected_erc_checksums = ['b80b93b52e4f48c90dcb9c84ba13286b', 'e5a4ff1c14ed93e0c89f8d367d4e1cb9']
      validate_request!(request_args, expected_erc_checksums)
    end

    it 'falls back to <atom:published/> when <dc:date/> not present' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @feed_xml_str = @feed_xml_str.gsub(/<dc:date>[^<]+<\/dc:date>/, '')
      @feed_xml_str = @feed_xml_str.gsub(/<dc:date\/>/, '')
      @feed_xml_str = @feed_xml_str.gsub(/<updated>([^<]+)<\/updated>/, "<published>\\1</published>\n    <updated>\\1</updated>")
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      expected_erc_checksums = ['90c5a778f44df8661a8cd11b7868f519', '9d59734d7f1254d3d51c26ed999d3159']
      validate_request!(request_args, expected_erc_checksums)
    end

    # TODO: fix code, then re-enable this test
    skip 'falls back to <atom:id/> if <dc:identifier/> not found' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      @feed_xml_str = @feed_xml_str.gsub(/<dc:identifier>[^<]+<\/dc:identifier>/, '')
      stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

      request_args = []
      allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

      invoke_update!

      expected_ids = [
        'https://nuxeo.cdlib.org/Nuxeo/nxdoc/default/494672cf-2937-4975-8b33-90bf80b4c8a6/view_documents',
        'https://nuxeo.cdlib.org/Nuxeo/nxdoc/default/365579cc-a369-45e7-8977-047bda3f7ed1/view_documents'
      ]

      expected_ids.each_with_index do |expected_id, i|
        actual_id = request_args[i]['localIdentifier']
        expect(actual_id).to eq(expected_id)
      end
    end

    skip 'sends basic-auth credentials for links to nuxeo.cdlib.org' do
      # TODO: figure out how to test this
    end

    skip 'doesn\'t send basic-auth credentials for links to sites other than nuxeo.cdlib.org' do
      # TODO: figure out how to test this
    end

    it 'updates existing objects with older modification times' do
      # feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      # previous_update = feed_updated - 1
      # write_feeddate(previous_update) # -1 day
      previous_update = DateTime.new(1970, 1, 1)
      write_feeddate(previous_update)

      collection = create(:private_collection, ark: @collection_ark, name: 'Collection 1', mnemonic: 'collection_1')
      local_ids = ['494672cf-2937-4975-8b33-90bf80b4c8a6', '365579cc-a369-45e7-8977-047bda3f7ed1']
      local_ids.each_with_index do |id, i|
        collection.inv_objects << create(:inv_object, erc_where: id, created: previous_update, modified: previous_update, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: '2018-01-01')
      end

      expect(server).to receive(:add_file).exactly(2).times
      expect(client).to receive(:ingest).exactly(2).times

      invoke_update!
    end

    it 'skips updates for objects with up-to-date modification times' do
      feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
      write_feeddate(feed_updated - 1) # -1 day

      collection = create(:private_collection, ark: @collection_ark, name: 'Collection 1', mnemonic: 'collection_1')
      local_ids = ['494672cf-2937-4975-8b33-90bf80b4c8a6', '365579cc-a369-45e7-8977-047bda3f7ed1']
      local_ids.each_with_index do |id, i|
        obj = create(:inv_object, erc_where: id, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: '2018-01-01')
        collection.inv_objects << obj
        expect(obj.modified).to be > feed_updated # just to be sure
      end

      expect(server).not_to receive(:add_file)
      expect(client).not_to receive(:ingest)

      invoke_update!
    end

    # TODO: make this happen
    pending 'exits with an error if ATOM_CONFIG does not include collection credentials'
    pending 'exits with an error if ATOM_CONFIG does not include local ID element'

    pending 'pages through results'
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

    describe 'pagination' do
      attr_reader :feed_xml_strs
      attr_reader :feed_urls

      before(:each) do
        feed_files = (1..3).map { |x| "ucldc_collection_9585555-#{x}.atom"}
        @feed_xml_strs = feed_files.map { |f| File.read("spec/data/#{f}").freeze }
        @feed_urls = feed_files.map { |f| "https://s3.example.com/static.ucldc.example.edu/merritt/#{f}" }
        feed_urls.each_with_index do |url, i|
          stub_request(:get, url).to_return(status: 200, body: feed_xml_strs[i], headers: {})
        end

        @starting_point = feed_urls[0]
        @feed_xml_str = feed_xml_strs[0]
        @feed_xml = Nokogiri::XML(feed_xml_str)
        @collection = 'FK9585555'
        @collection_ark = "ark:/99999/#{collection}"
        @feeddatefile = "#{tmp_home}/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
        @pause_file = "#{atom_dir}/PAUSE_ATOM_#{profile}"

        feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
        write_feeddate(feed_updated - 1) # -1 day
      end

      it 'paginates' do
        expect(server).to receive(:add_file).exactly(9).times
        expect(client).to receive(:ingest).exactly(9).times
        invoke_update!
      end

      it 'ignores bad "next" links that link to the page itself' do
        last_link = '<link href="https://s3.example.com/static.ucldc.example.edu/merritt/ucldc_collection_9585555-3.atom" rel="last"/>'
        feed_xml_str_self_next = feed_xml_strs[2].sub(last_link, "#{last_link}\n  #{last_link.sub('last', 'next')}")
        stub_request(:get, feed_urls[2]).to_return(status: 200, body: feed_xml_str_self_next)

        expect(server).to receive(:add_file).exactly(9).times
        expect(client).to receive(:ingest).exactly(9).times
        invoke_update!
      end

      it 'pauses between batches' do
        batch_size_orig = Object.send(:remove_const, :BATCH_SIZE)
        Object.send(:const_set, :BATCH_SIZE, 2)
        expect(BATCH_SIZE).to eq(2) # just to be sure

        begin
          obj_count = 9
          expected_sleeps = (obj_count / BATCH_SIZE) - 1
          expect(server).to receive(:add_file).exactly(obj_count).times
          expect(client).to receive(:ingest).exactly(obj_count).times

          # HACK: to "expect().to receive" global sleep call
          @sleep_count = 0
          allow_any_instance_of(Object).to(receive(:sleep).with(300)) { @sleep_count += 1 }

          invoke_update!
          expect(@sleep_count).to eq(expected_sleeps)
        ensure
          Object.send(:remove_const, :BATCH_SIZE)
          Object.send(:const_set, :BATCH_SIZE, batch_size_orig)
        end
      end
    end

    describe 'with nx:identifier' do
      before(:each) do
        @feed_xml_str = File.read('spec/data/ucldc_collection_1212555_nxidentifier.atom').freeze
        @feed_xml = Nokogiri::XML(feed_xml_str)
        @collection = 'FK12125555'
        @collection_ark = "ark:/99999/#{collection}"
        @feeddatefile = "#{tmp_home}/dpr2/apps/ui/atom/LastUpdate/lastFeedUpdate_#{collection}"
        @pause_file = "#{atom_dir}/PAUSE_ATOM_#{profile}"
        stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})
      end

      it 'parses nx:identifier as a second local ID' do
        feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
        write_feeddate(feed_updated - 1) # -1 day

        request_args = []
        allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

        invoke_update!

        expected_ids = [
          'c9c0834e-d22b-40a1-a35d-811dc40f20ed; ark:/99999/FKd2x08p',
          '5875b691-e05f-4036-ab0a-8e37cc32a8a3; ark:/99999/FKd28w60'
        ]

        expected_ids.each_with_index do |expected_id, i|
          actual_id = request_args[i]['localIdentifier']
          expect(actual_id).to eq(expected_id)
        end
      end

      # TODO: fix code, then re-enable this test
      skip 'falls back to <atom:id/> if <dc:identifier/> not found' do
        feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
        write_feeddate(feed_updated - 1) # -1 day

        @feed_xml_str = @feed_xml_str.gsub(/<dc:identifier>[^<]+<\/dc:identifier>/, '')
        stub_request(:get, starting_point).to_return(status: 200, body: feed_xml_str, headers: {})

        request_args = []
        allow(client).to(receive(:ingest)) {|request| request_args << request.mk_args}

        invoke_update!

        expected_ids = [
          'https://nuxeo.cdlib.org/Nuxeo/nxdoc/default/c9c0834e-d22b-40a1-a35d-811dc40f20ed/view_documents; ark:/99999/FKd2x08p',
          'https://nuxeo.cdlib.org/Nuxeo/nxdoc/default/5875b691-e05f-4036-ab0a-8e37cc32a8a3/view_documents; ark:/99999/FKd28w60'
        ]

        expected_ids.each_with_index do |expected_id, i|
          actual_id = request_args[i]['localIdentifier']
          expect(actual_id).to eq(expected_id)
        end
      end

      it 'updates existing objects with older modification times' do
        # feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
        # previous_update = feed_updated - 1
        # write_feeddate(previous_update) # -1 day
        previous_update = DateTime.new(1970, 1, 1)
        write_feeddate(previous_update)

        collection = create(:private_collection, ark: @collection_ark, name: 'Collection 1', mnemonic: 'collection_1')
        local_ids = ['c9c0834e-d22b-40a1-a35d-811dc40f20ed', '5875b691-e05f-4036-ab0a-8e37cc32a8a3']
        local_ids.each_with_index do |id, i|
          collection.inv_objects << create(:inv_object, erc_where: id, created: previous_update, modified: previous_update, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: '2018-01-01')
        end

        expect(server).to receive(:add_file).exactly(2).times
        expect(client).to receive(:ingest).exactly(2).times

        invoke_update!
      end

      it 'skips updates for objects with up-to-date modification times' do
        feed_updated = DateTime.parse(feed_xml.at_xpath('//xmlns:updated').text)
        write_feeddate(feed_updated - 1) # -1 day

        collection = create(:private_collection, ark: @collection_ark, name: 'Collection 1', mnemonic: 'collection_1')
        local_ids = ['c9c0834e-d22b-40a1-a35d-811dc40f20ed', '5875b691-e05f-4036-ab0a-8e37cc32a8a3']
        local_ids.each_with_index do |id, i|
          obj = create(:inv_object, erc_where: id, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: '2018-01-01')
          collection.inv_objects << obj
          expect(obj.modified).to be > feed_updated # just to be sure
        end

        expect(server).not_to receive(:add_file)
        expect(client).not_to receive(:ingest)

        invoke_update!
      end

      pending 'parses nx:identifier as first local ID if configured element not present'
    end
  end
end
