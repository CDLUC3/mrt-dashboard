require 'rails_helper'
require 'support/presigned'

RSpec.describe ObjectController, type: :controller do
  include MerrittRetryMixin

  attr_reader :user_id

  attr_reader :collection
  attr_reader :collection_id
  attr_reader :objects

  attr_reader :object
  attr_reader :object_ark

  attr_reader :file
  attr_reader :client

  describe 'default filenames' do
    before(:each) do
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

      @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
      @collection_id = mock_ldap_for_collection(collection)
      @objects = []
      3.times do |i|
        @objects.append(
          create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}")
        )
        sleep 1
      end
      collection.inv_objects << objects

      @object_ark = objects[0].ark
      @object = objects[0]

      # @file = Rack::Test::UploadedFile.new('tempfile.foo', content_type='application/octet-stream', binary=true)
      @file = double(ActionDispatch::Http::UploadedFile)
      allow(file).to receive(:tempfile).and_return('tempfile.foo')
      allow(file).to receive(:original_filename).and_return('original_filename.foo')

      # trick ActionController::TestCase.paramify_values into accepting the double
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
            request.session.merge!({ uid: nil })
            post(method, params: params)
            expect(response.status).to eq(401)
          end

          it "returns 400 if file is not an #{ActionDispatch::Http::UploadedFile} or similar" do
            mock_permissions_all(user_id, collection_id)
            params[:file] = 'example.tmp'
            request.session.merge!({ uid: user_id })
            post(method, params: params)
            expect(response.status).to eq(400)
          end

          it 'returns 404 when user doesn\'t have write permission' do
            mock_permissions_read_only(user_id, collection_id)
            request.session.merge!({ uid: user_id })
            post(method, params: params)
            expect(response.status).to eq(404)
          end
        end

        describe 'request' do
          attr_reader :expected_params
          attr_reader :ingest_response

          before(:each) do
            mock_permissions_all(user_id, collection_id)
            @expected_params = {
              'file' => file.tempfile,
              'filename' => file.original_filename,
              'submitter' => "#{user_id}/Jane Doe",
              'profile' => params[:profile]
            }

            ingest_status = 200
            ingest_headers = { content_type: 'text/plain; charset=utf-8' }
            ingest_body = 'this is the body of the response'
            @ingest_response = instance_double(HTTP::Message)
            allow(ingest_response).to receive(:status).and_return(ingest_status)
            allow(ingest_response).to receive(:headers).and_return(ingest_headers)
            allow(ingest_response).to receive(:body).and_return(ingest_body)
          end

          it 'posts the argument to the ingest service as a multipart form' do
            expect(client).to receive(:post).with(
              APP_CONFIG[url_config_key], expected_params
            ).and_return(ingest_response)

            request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
            request.session.merge!({ uid: user_id })
            post(method, params: params)
          end

          it 'forwards the status, content-type, and body from the ingest response' do
            expect(client).to receive(:post).with(
              APP_CONFIG[url_config_key], expected_params
            ).and_return(ingest_response)

            request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
            request.session.merge!({ uid: user_id })
            post(method, params: params)

            expect(response.status).to eq(ingest_response.status)
            expect(response.content_type).to eq(ingest_response.headers[:content_type])
            expect(response.body).to eq(ingest_response.body)
          end

          it 'allows the filename parameter to override the uploaded file' do
            params[:filename] = 'not-the-original-filename.bin'
            expected_params['filename'] = params[:filename]
            expect(client).to receive(:post).with(
              APP_CONFIG[url_config_key], expected_params
            ).and_return(ingest_response)

            request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
            request.session.merge!({ uid: user_id })
            post(method, params: params)
          end

          if method == :ingest
            it 'allows the submitter parameter to override the current user' do
              params['submitter'] = 'Rachel Roe'
              expected_params['submitter'] = params['submitter']
              expect(client).to receive(:post).with(
                APP_CONFIG[url_config_key], expected_params
              ).and_return(ingest_response)

              request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
              request.session.merge!({ uid: user_id })
              post(method, params: params)
            end
          end
        end
      end
    end

    describe ':index' do
      it 'prevents index view without read permission' do
        request.session.merge!({ uid: user_id })
        get(:index, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'successful object load' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })
        get(:index, params: { object: object_ark })
        expect(response.status).to eq(200)
      end

      it 'successful object load - retry failure on load_object' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })
        allow(InvObject)
          .to receive(:where)
          .with(any_args)
          .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

        expect do
          get(:index, params: { object: object_ark })
        end.to raise_error(MerrittRetryMixin::RetryException)
      end

    end

    describe ':object_info' do
      it 'prevents object_info view without read permission' do
        request.session.merge!({ uid: user_id })
        get(:object_info, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'prevents audit_replic view without read permission' do
        request.session.merge!({ uid: user_id })
        get(:audit_replic, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'returns object_info as json' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        get(:object_info, params: { object: object_ark })
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['ark']).to eq(object_ark)
        expect(json['versions'][0]['version_number']).to eq(1)
      end

      it 'returns audit_replic if user is authorized' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        get(:audit_replic, params: { object: object_ark })
        expect(response.status).to eq(200)
      end

      it 'returns versioned object_info as json' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        create(
          :inv_version,
          inv_object: object,
          ark: object_ark,
          number: object.current_version.number + 1,
          note: 'Sample Version 2'
        ).save!

        get(:object_info, params: { object: object_ark })
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['ark']).to eq(object_ark)
        expect(json['versions'][0]['version_number']).to eq(2)
      end

      it 'returns object_info with localid as json' do
        lid = InvLocalid.new(
          local_id: 'test-localid',
          inv_object: @objects[0],
          inv_owner: @objects[0].inv_owner,
          created: Time.now
        )
        lid.save!

        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        get(:object_info, params: { object: object_ark })
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['localids']).to include('test-localid')
      end

      it 'returns object_info with files as json' do
        inv_file = create(
          :inv_file,
          inv_object: @objects[0],
          inv_version: @objects[0].current_version,
          pathname: 'producer/foo.bin',
          mime_type: 'application/octet-stream',
          billable_size: 1000
        )
        inv_file.save!

        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        get(:object_info, params: { object: object_ark })
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['versions'][0]['files'][0]['pathname']).to eq('producer/foo.bin')
      end

      it 'returns object_info with files starting at index 1 as json' do
        inv_file = create(
          :inv_file,
          inv_object: @objects[0],
          inv_version: @objects[0].current_version,
          pathname: 'producer/foo.bin',
          mime_type: 'application/octet-stream',
          billable_size: 1000
        )
        inv_file.save!

        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        get(:object_info, params: { object: object_ark, index: 1 })
        expect(response.status).to eq(200)
      end

      it 'returns object_info with files as json - retry failure' do
        inv_file = create(
          :inv_file,
          inv_object: @objects[0],
          inv_version: @objects[0].current_version,
          pathname: 'producer/foo.bin',
          mime_type: 'application/octet-stream',
          billable_size: 1000
        )
        inv_file.save!

        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })

        allow_any_instance_of(InvVersion)
          .to receive(:inv_files)
          .with(any_args)
          .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

        expect do
          get(:object_info, params: { object: object_ark })
        end.to raise_error(MerrittRetryMixin::RetryException)
      end
    end

    describe ':download' do
      it 'requires a login' do
        request.session.merge!({ uid: nil })
        get(:download, params: { object: object_ark })
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include('guest_login')
      end

      it 'prevents download without permissions' do
        request.session.merge!({ uid: user_id })
        get(:download, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'prevents download when download size exceeded' do
        mock_permissions_all(user_id, collection_id)
        size_too_large = 1 + APP_CONFIG['max_download_size']
        allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(size_too_large)
        request.session.merge!({ uid: user_id })
        get(:download, params: { object: object_ark })
        expect(response.status).to eq(403)
      end

      it 'returns 413 when sync download size exceeded' do
        mock_permissions_all(user_id, collection_id)
        size_too_large = 1 + APP_CONFIG['max_archive_size']
        allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(size_too_large)
        request.session.merge!({ uid: user_id })
        get(:download, params: { object: object_ark })
        expect(response.status).to eq(413)
      end

      it 'streams the object as a zipfile' do
        mock_permissions_all(user_id, collection_id)

        streamer = double(Streamer)
        expected_url = "#{object.bytestream_uri}?t=zip"
        allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

        request.session.merge!({ uid: user_id })
        get(:download, params: { object: object_ark })

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

    describe ':presign' do
      attr_reader :params

      before(:each) do
        @params = { object: object_ark }
      end

      it 'requires a login' do

        request.session.merge!({ uid: nil })
        get(:presign, params: params)
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include('guest_login')
      end

      it 'prevents presign without permissions' do
        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(401)
      end

      it 'request async assembly of an object' do
        mock_permissions_all(user_id, collection_id)
        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          response_assembly_200('aaa')
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['token']).to eq('aaa')
      end

      it 'request async assembly of an object with content and format' do
        mock_permissions_all(user_id, collection_id)

        reqparam = { content: 'producer', format: 'tar' }
        params[:content] = reqparam[:content]
        params[:format]  = reqparam[:format]

        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          response_assembly_200('aaa'),
          reqparam
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['token']).to eq('aaa')
      end

      it 'request async assembly of an object with content and format sanitized' do
        mock_permissions_all(user_id, collection_id)

        params[:content] = 'bogus'
        params[:format] = 'bogus'
        params[:extra] = 'bogus'

        # params above will be sanitized
        reqparam = {}

        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          response_assembly_200('aaa'),
          reqparam
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['token']).to eq('aaa')
      end

      it 'simulate 403 (object on glacier) from storage servcie' do
        mock_permissions_all(user_id, collection_id)
        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          general_response_403
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(403)
      end

      it 'simulate 404 from the storage service' do
        mock_permissions_all(user_id, collection_id)
        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          general_response_404
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(404)
      end

      it 'simulate 500 from the storage service' do
        mock_permissions_all(user_id, collection_id)

        mock_assembly(
          @object.node_number,
          ApplicationController.encode_storage_key(@object.ark),
          general_response_500
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(500)
      end

      it 'simulate timeout from the storage service - returns 408' do
        mock_permissions_all(user_id, collection_id)

        client = mock_httpclient
        nk = {
          node_id: @object.node_number,
          key: ApplicationController.encode_storage_key(@object.ark)
        }
        expect(client).to receive(:post).with(
          ApplicationController.get_storage_presign_url(nk, has_file: false, params: {}),
          follow_redirect: true
        ).and_raise(
          HTTPClient::ReceiveTimeoutError
        )

        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(408)
      end

      it 'request async assembly of a non-existent object' do
        mock_permissions_all(user_id, collection_id)
        params[:object] = "#{object_ark}_non_exist"
        request.session.merge!({ uid: user_id })
        get(:presign, params: params)
        expect(response.status).to eq(404)
      end
    end

    describe ':download_user' do
      it 'requires a login' do
        request.session.merge!({ uid: nil })
        get(:download_user, params: { object: object_ark })
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include('guest_login')
      end

      it 'prevents download without permissions' do
        request.session.merge!({ uid: user_id })
        get(:download_user, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'streams the object\'s producer files as a zipfile' do
        mock_permissions_all(user_id, collection_id)

        streamer = double(Streamer)
        expected_url = "#{object.bytestream_uri2}?t=zip"
        allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

        request.session.merge!({ uid: user_id })
        get(:download_user, params: { object: object_ark })

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

    describe ':download_manifest' do
      it 'requires a login' do
        request.session.merge!({ uid: nil })
        get(:download_user, params: { object: object_ark })
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include('guest_login')
      end

      it 'prevents download without permissions' do
        request.session.merge!({ uid: user_id })
        get(:download_user, params: { object: object_ark })
        expect(response.status).to eq(401)
      end

      it 'streams the manifest as XML' do
        mock_permissions_all(user_id, collection_id)

        streamer = double(Streamer)
        expected_url = object.bytestream_uri3.to_s
        allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

        request.session.merge!({ uid: user_id })
        get(:download_manifest, params: { object: object_ark })

        expect(response.status).to eq(200)

        expected_filename = Orchard::Pairtree.encode(object_ark).to_s
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
        @session = { uid: user_id, group_id: collection_id }
      end

      it 'requires a login' do
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: nil })
        post(:upload, params: params)
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to include('guest_login')
      end

      it 'redirects and displays an error when no file provided' do
        params.delete(:file)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!(session)
        post(:upload, params: params)
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
        allow(ingest_response).to receive(:status).and_return(200)
        allow(ingest_response).to receive(:content).and_return(xml)

        expect(client).to receive(:post).with(
          APP_CONFIG['ingest_service_update'], expected_params
        ).and_return(ingest_response)

        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!(session)
        post(:upload, params: params)

        expect(response.status).to eq(302)
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

        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!(session)
        post(:upload, params: params)

        expect(controller.instance_variable_get(:@description)).to eq("ingest: #{status_desc}")
        expect(controller.instance_variable_get(:@error)).to eq("ingest: #{error}")
      end
    end

    describe ':recent_items_feed_unauthenticated' do

      render_views

      it 'gets the list of objects' do
        request.accept = 'application/atom+xml'
        get(:recent, params: { collection: collection.ark })
        expect(response.status).to eq(401)
      end
    end

    describe ':recent_items_feed_authenticated' do

      before(:each) do
        request.session.merge!({ uid: user_id })
      end

      render_views

      it '404s cleanly when collection does not exist' do
        bad_ark = ArkHelper.next_ark
        get(:recent, params: { collection: bad_ark })
        expect(response.status).to eq(404)
      end

      it 'gets the list of objects' do
        mock_permissions_all(user_id, collection_id)
        request.accept = 'application/atom+xml'
        get(:recent, params: { collection: collection.ark })
        expect(response.status).to eq(200)
        expect(response.content_type).to eq('application/atom+xml; charset=utf-8')

        body = response.body
        objects.each do |obj|
          expect(body).to include(obj.ark)
        end
      end

      it 'gets the list of objects - retry failure on query' do
        mock_permissions_all(user_id, collection_id)
        allow(InvCollection)
          .to receive(:where)
          .with(any_args)
          .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

        expect do
          get(:recent, params: { collection: collection.ark })
        end.to raise_error(MerrittRetryMixin::RetryException)
      end

      it 'gets the list of objects - no collection permissions' do
        request.accept = 'application/atom+xml'
        get(:recent, params: { collection: collection.ark })
        expect(response.status).to eq(401)
      end

      it 'gets a list of 2 objects' do
        mock_permissions_all(user_id, collection_id)
        request.accept = 'application/atom+xml'
        get(:recent, params: { collection: collection.ark, per_page: 2 })
        expect(response.status).to eq(200)
        expect(response.content_type).to eq('application/atom+xml; charset=utf-8')

        body = response.body
        expect(body).to include('per_page=2')
        expect(body).to include(objects[2].ark)
        expect(body).to include(objects[1].ark)
        expect(body).not_to include(objects[0].ark)
      end

      it 'request 1000, page size set to 500' do
        mock_permissions_all(user_id, collection_id)
        request.accept = 'application/atom+xml'
        get(:recent, params: { collection: collection.ark, per_page: 1000 })
        expect(response.status).to eq(200)
        expect(response.content_type).to eq('application/atom+xml; charset=utf-8')

        body = response.body
        expect(body).to include('per_page=500')
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

  describe 'special filenames' do
    before(:each) do
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

      @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
      @collection_id = mock_ldap_for_collection(collection)
      @objects = Array.new(3) { |i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}") }
      collection.inv_objects << objects

      @object_ark = objects[0].ark
      @object = objects[0]

      # @file = Rack::Test::UploadedFile.new('tempfile.foo', content_type='application/octet-stream', binary=true)
      @file = double(ActionDispatch::Http::UploadedFile)
      allow(file).to receive(:tempfile).and_return('tempfile.foo')
      allow(file).to receive(:param_filename).and_return('original_filename %AF.foo')
      allow(file).to receive(:original_filename).and_return(Encoder.urlunencode('original_filename %AF.foo'))
      allow(file).to receive(:headers).and_return('Content-Disposition: form-data; name="file"; filename="original_filename %AF.foo"')

      # trick ActionController::TestCase.paramify_values into accepting the double
      allow(file).to receive(:to_param).and_return(file)

      APP_CONFIG['post_upload'] = 'http://ingest.merritt.example.edu/poster/update/'

      @client = mock_httpclient
    end

    {
      ingest: 'ingest_service',
      update: 'ingest_service_update',
      upload: 'post_upload'
    }.each do |method, url_config_key|
      describe ":#{method}" do
        attr_reader :params

        before(:each) do
          @params = {
            file: file,
            profile: "#{collection_id}_profile"
          }
        end
        describe 'request' do
          attr_reader :expected_params
          attr_reader :ingest_response

          before(:each) do
            mock_permissions_all(user_id, collection_id)
            request.session.merge!({ uid: user_id })
            @expected_params = {
              'file' => file.tempfile,
              'submitter' => "#{user_id}/Jane Doe",
              'profile' => params[:profile]
            }

            session[:group_id] = mock_ldap_for_collection(collection)

            ingest_status = 200
            ingest_headers = { content_type: 'text/plain' }
            ingest_body = 'this is the body of the response'
            xmlresp = '<doc xmlns:bat="foo"><bat:batchState><bat:batchID>1</bat:batchID></bat:batchState></doc>'
            @ingest_response = instance_double(HTTP::Message)
            allow(ingest_response).to receive(:status).and_return(ingest_status)
            allow(ingest_response).to receive(:headers).and_return(ingest_headers)
            allow(ingest_response).to receive(:body).and_return(ingest_body)
            allow(ingest_response).to receive(:content).and_return(xmlresp)
          end

          it 'posts the argument to the ingest service as a multipart form' do
            expect(client).to receive(:post).with(
              APP_CONFIG[url_config_key], hash_including(expected_params)
            ).and_return(ingest_response)

            request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
            request.session.merge!({ uid: user_id })

            post(method, params: params)
          end
        end
      end
    end

  end

end
