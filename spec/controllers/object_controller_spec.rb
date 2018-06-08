require 'rails_helper'

describe ObjectController do

  attr_reader :user_id

  attr_reader :collection
  attr_reader :collection_id
  attr_reader :objects

  attr_reader :object
  attr_reader :object_ark

  attr_reader :file
  attr_reader :client

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
    @objects = Array.new(3) {|i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}")}
    collection.inv_objects << objects

    @object_ark = objects[0].ark
    @object = objects[0]

    # @file = Rack::Test::UploadedFile.new('tempfile.foo', content_type='application/octet-stream', binary=true)
    @file = double(ActionDispatch::Http::UploadedFile)
    allow(file).to receive(:tempfile).and_return('tempfile.foo')
    allow(file).to receive(:original_filename).and_return('original_filename.foo')

    # hack to trick ActionController::TestCase.paramify_values into accepting the double
    allow(file).to receive(:to_param).and_return(file)

    @client = mock_httpclient
  end

  {
    ingest: 'ingest_service',
    update: 'ingest_service_update'
  }.each do |method, url_config_key|
    describe ":#{method}" do
      attr_reader :params

      before(:each) do
        @params = {
          file: file,
          profile: "#{collection_id}_profile"
        }
      end

      describe 'restrictions' do
        it 'returns 401 when user not logged in' do
          @request.headers['HTTP_AUTHORIZATION'] = nil
          post(method, params, {uid: nil})
          expect(response.status).to eq(401)
        end

        it "returns 400 if file is not an #{ActionDispatch::Http::UploadedFile} or similar" do
          params[:file] = 'example.tmp'
          post(method, params, {uid: user_id})
          expect(response.status).to eq(400)
        end

        it 'returns 404 when user doesn\'t have write permission' do
          mock_permissions_read_only(user_id, collection_id)
          post(method, params, {uid: user_id})
          expect(response.status).to eq(404)
        end
      end

      describe 'request' do
        attr_reader :expected_params
        attr_reader :ingest_response

        before(:each) do
          mock_permissions_all(user_id, collection_id)
          @expected_params = {
            "file" => file.tempfile,
            "filename" => file.original_filename,
            "submitter" => "#{user_id}/Jane Doe",
            "profile" => params[:profile]
          }

          ingest_status = 200
          ingest_headers = {content_type: 'text/plain'}
          ingest_body = "this is the body of the response"
          @ingest_response = instance_double(HTTP::Message)
          allow(ingest_response).to receive(:status).and_return(ingest_status)
          allow(ingest_response).to receive(:headers).and_return(ingest_headers)
          allow(ingest_response).to receive(:body).and_return(ingest_body)
        end

        it 'posts the argument to the ingest service as a multipart form' do
          expect(client).to receive(:post).with(
            APP_CONFIG[url_config_key], expected_params, {'Content-Type' => 'multipart/form-data'}
          ).and_return(ingest_response)

          post(method, params, {uid: user_id})
        end

        it 'forwards the status, content-type, and body from the ingest response' do
          allow(client).to receive(:post).with(
            APP_CONFIG[url_config_key], expected_params, {'Content-Type' => 'multipart/form-data'}
          ).and_return(ingest_response)

          post(method, params, {uid: user_id})

          expect(response.status).to eq(ingest_response.status)
          expect(response.content_type).to eq(ingest_response.headers[:content_type])
          expect(response.body).to eq(ingest_response.body)
        end

        it 'allows the filename parameter to override the uploaded file' do
          params[:filename] = 'not-the-original-filename.bin'
          expected_params['filename'] = params[:filename]
          expect(client).to receive(:post).with(
            APP_CONFIG[url_config_key], expected_params, {'Content-Type' => 'multipart/form-data'}
          ).and_return(ingest_response)

          post(method, params, {uid: user_id})
        end

        if method == :ingest
          it 'allows the submitter parameter to override the current user' do
            params['submitter'] = 'Rachel Roe'
            expected_params['submitter'] = params['submitter']
            expect(client).to receive(:post).with(
              APP_CONFIG[url_config_key], expected_params, {'Content-Type' => 'multipart/form-data'}
            ).and_return(ingest_response)

            post(method, params, {uid: user_id})
          end
        end
      end
    end
  end

  describe ':mint' do
    attr_reader :params
    before(:each) do
      @params = {
        profile: "#{collection_id}_profile",
        erc: 'who: Herschlag, Natalie%0Awhat: An Account of a Very Odd Monstrous Calf',
        responseForm: 'xml'
      }
    end

    it 'requires a user' do
      @request.headers['HTTP_AUTHORIZATION'] = nil
      post(:mint, params, {uid: nil})
      expect(response.status).to eq(401)
    end

    it 'requires the user to have write permissions on the current submission profile' do
      mock_permissions_read_only(user_id, collection_id)
      post(:mint, params, {uid: user_id})
      expect(response.status).to eq(404)
    end

    it 'posts a mint request' do
      mock_permissions_all(user_id, collection_id)

      mint_status = 200
      mint_headers = {content_type: 'text/xml'}
      mint_body = "<xml>12345</xml>"
      mint_response = instance_double(HTTP::Message)
      allow(mint_response).to receive(:status).and_return(mint_status)
      allow(mint_response).to receive(:headers).and_return(mint_headers)
      allow(mint_response).to receive(:body).and_return(mint_body)

      expected_params = {
        'profile' => params[:profile],
        'erc' => params[:erc],
        'responseForm' => params[:responseForm]
      }
      expect(client).to receive(:post).with(
        APP_CONFIG['mint_service'],
        hash_including(expected_params),
        {"Content-Type" => "multipart/form-data"}
      ).and_return(mint_response)

      post(:mint, params, {uid: user_id})

      expect(response.status).to eq(mint_response.status)
      expect(response.content_type).to eq(mint_response.headers[:content_type])
      expect(response.body).to eq(mint_response.body)
    end
  end

  describe ':index' do
    it 'prevents index view without read permission' do
      get(:index, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(401)
    end
  end

  describe ':download' do
    it 'requires a login' do
      get(:download, {object: object_ark}, {uid: nil})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:download, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(401)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_download_size']
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(size_too_large)
      get(:download, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(403)
    end

    it "redirects to #{LostorageController} when sync download size exceeded" do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_archive_size']
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(size_too_large)
      get(:download, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('lostorage')
    end

    it 'streams the object as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:download, {object: object_ark}, {uid: user_id})

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
      get(:downloadUser, {object: object_ark}, {uid: nil})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:downloadUser, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(401)
    end

    it 'streams the object\'s producer files as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri2}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:downloadUser, {object: object_ark}, {uid: user_id})

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
      get(:downloadUser, {object: object_ark}, {uid: nil})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:downloadUser, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(401)
    end

    it 'streams the manifest as XML' do
      mock_permissions_all(user_id, collection_id)

      streamer = double(Streamer)
      expected_url = "#{object.bytestream_uri3}"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:downloadManifest, {object: object_ark}, {uid: user_id})

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
      get(:async, {object: object_ark}, {uid: nil})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'fails when object is too big for any download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_download_size'])
      get(:async, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(403)
    end

    it 'fails when object is too small for asynchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(APP_CONFIG['max_archive_size'] - 1)
      get(:async, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(406)
    end

    it 'succeeds when object is the right size for synchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_archive_size'])
      get(:async, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(200)
    end
  end

  describe ':upload' do
    attr_reader :params
    attr_reader :session

    before(:each) do
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
      @session = {uid: user_id, group_id: collection_id}
    end

    it 'requires a login' do
      post(:upload, params, {uid: nil})
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    # TODO: why not?
    # it 'requires write permission' do
    #   post(:upload, params, session)
    #   expect(response.status).to eq(403)
    # end

    it 'redirects and displays an error when no file provided' do
      params.delete(:file)
      post(:upload, params, session)
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to end_with("/a/#{collection_id}")
    end

    it 'posts an update to the ingest service' do
      mock_permissions_all(user_id, collection_id)

      expected_params = {
        'file' => file.tempfile,
        'type' => params[:object_type],
        'submitter' => "#{user_id}/Jane Doe",
        'filename' => file.original_filename,
        'profile' => "#{collection_id}_profile",
        'creator' => params[:author],
        'title' => params[:title],
        'primaryIdentifier' => params[:primary_id],
        'date' => params[:date],
        'localIdentifier' => params[:local_id],
        'responseForm' => 'xml'
      }

      batch_id = '12345'
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

    it 'handles errors' do
      mock_permissions_all(user_id, collection_id)

      status_desc = 'I am the status description'
      error = 'I am the error'

      xml = <<-XML
        <exc:batchState xmlns:exc='http://example.org/exc'>
          <exc:statusDescription>#{status_desc}</exc:statusDescription>
          <exc:error>#{error}</exc:error>
        </exc:batchState>
      XML

      ex = Exception.new
      allow(ex).to receive(:response).and_return(xml)

      expect(client).to receive(:post).with(APP_CONFIG['ingest_service_update'], anything).and_raise(ex)

      post(:upload, params, session)

      expect(controller.instance_variable_get(:@description)).to eq("ingest: #{status_desc}")
      expect(controller.instance_variable_get(:@error)).to eq("ingest: #{error}")
    end
  end

  describe ':recent' do
    render_views

    it '404s cleanly when collection does not exist' do
      bad_ark = ArkHelper.next_ark
      get(:recent, {collection: bad_ark})
      expect(response.status).to eq(404)
    end

    it 'gets the list of objects' do
      request.accept = 'application/atom+xml'
      get(:recent, {collection: collection.ark})
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
