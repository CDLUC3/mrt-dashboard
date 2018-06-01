require 'rails_helper'

describe ObjectController do

  attr_reader :user_id

  attr_reader :collection
  attr_reader :collection_id
  attr_reader :objects

  attr_reader :object
  attr_reader :object_ark

  def mock_httpclient
    params = {
      receive_timeout: 7200,
      send_timeout: 3600,
      connect_timeout: 7200,
      keep_alive_timeout: 3600
    }
    client = instance_double(HTTPClient)
    params.each do |param, value|
      writer = "#{param}=".to_sym
      allow(client).to receive(writer).with(value)
    end
    allow(HTTPClient).to receive(:new).and_return(client)
    client
  end

  before(:each) do
    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)
    @objects = Array.new(3) { |i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}") }
    collection.inv_objects << objects

    @object_ark = objects[0].ark
    @object = objects[0]

    @client = begin

    end
  end

  # TODO: ditto for update, or shared examples
  describe ':ingest' do
    describe 'request' do
      it 'posts the argument to the ingest service as a multipart form'
      it 'forwards the response from the ingest service'
    end

    describe 'restrictions' do
      it 'returns 401 when user not logged in'
      it "returns 400 when file parameter is not a #{ActionDispatch::Http::UploadedFile} or similar"
      it "returns 404 when user doesn't have write permission"
    end

    describe 'filename' do
      it 'sets the filename based on the provided filename'
      it "sets the filename based on the provided #{ActionDispatch::Http::UploadedFile} or similar"
    end

    describe 'submitter' do
      it 'sets the submitter based on the provided submitter parameter'
      it 'sets the submitter based on the current user'
    end
  end

  describe ':mint' do
    it 'requires a user'
    it 'requires the user to have write permissions on the current submission profile'
    it 'posts a mint request'
    it 'forwards the response from the minting service'
  end

  describe ':index' do
    it 'prevents index view without read permission'
  end

  describe ':download' do
    it 'requires a login' do
      get(:download, { object: object_ark }, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:download, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_download_size'])
      get(:download, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it "redirects to #{LostorageController} when sync download size exceeded" do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_archive_size'])
      get(:download, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('lostorage')
    end

    it 'streams the object as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:download, { object: object_ark }, { uid: user_id })

      expect(response.status).to eq(200)

      expected_filename = "#{Orchard::Pairtree.encode(object_ark)}_object.zip"
      expected_headers = {
        'Content-Type' => 'application/zip',
        'Content-Disposition' => "attachment; filename=\"#{expected_filename}\""
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end
  end

  describe ':downloadUser' do
    it 'requires a login' do
      get(:downloadUser, { object: object_ark }, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:downloadUser, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it "streams the object's producer files as a zipfile" do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri2}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:downloadUser, { object: object_ark }, { uid: user_id })

      expect(response.status).to eq(200)

      expected_filename = "#{Orchard::Pairtree.encode(object_ark)}_object.zip"
      expected_headers = {
        'Content-Type' => 'application/zip',
        'Content-Disposition' => "attachment; filename=\"#{expected_filename}\""
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end
  end

  describe ':downloadManifest' do
    it 'requires a login' do
      get(:downloadUser, { object: object_ark }, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:downloadUser, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'streams the manifest as XML' do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri3}"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:downloadManifest, { object: object_ark }, { uid: user_id })

      expect(response.status).to eq(200)

      expected_filename = "#{Orchard::Pairtree.encode(object_ark)}"
      expected_headers = {
        'Content-Type' => 'text/xml',
        'Content-Disposition' => "attachment; filename=\"#{expected_filename}\""
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end
  end

  describe ':async' do
    it 'requires a login' do
      get(:async, { object: object_ark }, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'fails when object is too big for any download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_download_size'])
      get(:async, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it 'fails when object is too small for asynchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(APP_CONFIG['max_archive_size'] - 1)
      get(:async, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(406)
    end

    it 'succeeds when object is the right size for synchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_archive_size'])
      get(:async, { object: object_ark }, { uid: user_id })
      expect(response.status).to eq(200)
    end
  end

  describe ':upload' do
    attr_reader :file
    attr_reader :client
    attr_reader :params
    attr_reader :session

    before(:each) do
      # @file = Rack::Test::UploadedFile.new('tempfile.foo', content_type='application/octet-stream', binary=true)
      @file = double(ActionDispatch::Http::UploadedFile)
      allow(file).to receive(:tempfile).and_return('tempfile.foo')
      allow(file).to receive(:original_filename).and_return('original_filename.foo')

      # hack to trick ActionController::TestCase.paramify_values into accepting the double
      allow(file).to receive(:to_param).and_return(file)

      @params = {
        object: object_ark, # TODO: is this right?
        file: file,
        object_type: 'MRT-curatorial',
        author: 'N. Herschlag',
        title: 'An Account of a Very Odd Monstrous Calf',
        primary_id: object_ark, # TODO: is this right?
        date: Time.now.to_param,
        local_id: 'doi:10.1098/rstl.1665.0007'
      }
      @session = { uid: user_id, group_id: collection_id }

      @client = mock_httpclient
    end

    it 'requires a login' do
      post(:async, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    # TODO: why not?
    # it 'requires write permission' do
    #   post(:upload, params, session)
    #   expect(response.status).to eq(403)
    # end

    it 'redirects and displays an error when no file provided'

    it 'posts an update to the ingest service' do
      mock_permissions_all(user_id, collection_id)

      expected_params = {
        'file'              => params[:file].tempfile,
        'type'              => params[:object_type],
        'submitter'         => "#{user_id}/Jane Doe",
        'filename'          => params[:file].original_filename,
        'profile'           => "#{collection_id}_profile",
        'creator'           => params[:author],
        'title'             => params[:title],
        'primaryIdentifier' => params[:primary_id],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id],
        'responseForm'      => 'xml'
      }

      batch_id = "12345"
      xml = <<-XML
        <bat:batchState xmlns:bat='http://example.org/bat'>
          <bat:batchID>#{batch_id}</bat:batchID>
          <bat:jobStates/>
          <bat:jobStates/>
          <bat:jobStates/>
        </bat:batchState>
      XML
      ingest_response = instance_double(HTTP::Message)
      allow(ingest_response).to receive(:content).and_return(xml)

      expect(client).to receive(:post).with(APP_CONFIG['ingest_service_update'], expected_params).and_return(ingest_response)

      post(:upload, params, session)

      expect(response.status).to eq(200)
      expect(controller.instance_variable_get('@batch_id')).to eq(batch_id)
      expect(controller.instance_variable_get('@obj_count')).to eq(3)
    end

    it 'handles errors'
  end

  describe ':recent' do
    render_views

    it '404s cleanly when collection does not exist' do
      bad_ark = ArkHelper.next_ark
      get(:recent, { collection: bad_ark })
      expect(response.status).to eq(404)
    end

    it 'gets the list of objects' do
      request.accept = 'application/atom+xml'
      get(:recent, { collection: collection.ark })
      expect(response.status).to eq(200)
      expect(response.content_type).to eq('application/atom+xml')

      body = response.body
      objects.each do |obj|
        expect(body).to include(obj.ark)
      end
    end
  end

  describe ':mk_httpclient' do
    it 'configures and returns an HTTP client' do
      client = mock_httpclient
      result = controller.send(:mk_httpclient) # private method
      expect(result).to be(client)
    end
  end

end
