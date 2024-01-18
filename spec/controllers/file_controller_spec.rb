require 'rails_helper'
require 'support/presigned'

RSpec.describe FileController, type: :controller do
  include MerrittRetryMixin

  attr_reader :user_id
  attr_reader :collection
  attr_reader :collection_id

  attr_reader :object
  attr_reader :object_ark

  attr_reader :inv_file
  attr_reader :pathname
  attr_reader :basename
  attr_reader :client

  before(:each) do
    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)

    @object = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    collection.inv_objects << object
    @object_ark = object.ark

    # Ensure the consistency of the object ark and version ark
    object.current_version.ark = @object_ark
    object.current_version.save!

    @inv_file = create(
      :inv_file,
      inv_object: object,
      inv_version: object.current_version,
      pathname: 'producer/foo.bin',
      mime_type: 'application/octet-stream',
      billable_size: 1000
    )

    @pathname = inv_file.pathname
    @basename = File.basename(pathname)
    @client = mock_httpclient
  end

  describe ':download' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, file: pathname, version: object.current_version.number }
    end

    it 'requires a login' do
      request.session.merge!({ uid: nil })
      get(:download, params: params)
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      request.session.merge!({ uid: user_id })
      get(:download, params: params)
      expect(response.status).to eq(401)
    end

    it 'download file deprecated' do
      mock_permissions_all(user_id, collection_id)
      request.session.merge!({ uid: user_id })
      get(:download, params: params)
      expect(response.status).to eq(308)
      expect(response.body).to eq('')
      expect(response.headers).to have_key('Location')
    end

  end

  describe ':presign' do
    attr_reader :params

    # Simulated presign url
    def my_presign
      "#{inv_file.bytestream_uri}?presign=pretend"
    end

    # Simulated response from the storage service presign file request
    def my_node_key_params(params)
      request.session.merge!({ uid: user_id })
      r = get(:storage_key, params: params)
      json = JSON.parse(r.body)
      {
        node_id: json['node_id'],
        key: json['key']
      }
    end

    # Simulated presign response
    def my_presign_wrapper
      exp = Time.now + (60 * 60 * 24)
      {
        status: 200,
        url: my_presign,
        expires: exp.strftime('%Y-%m-%dT%H:%M:%S%:z'),
        message: 'Presigned URL created'
      }.with_indifferent_access
    end

    before(:each) do
      @params = { object: object_ark, file: pathname, version: object.current_version.number }
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

    it 'verify that presign request does not contain duplicate slashes' do
      url = FileController.get_storage_presign_url(my_node_key_params(params), has_file: true)
      expect(url).not_to match('https?://.*//')
    end

    it 'verify that external download url does not contain duplicate slashes' do
      url = inv_file.external_bytestream_uri.to_s
      expect(url).not_to match('https?://.*//.*')
    end

    it 'redirects to presign url for the file' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(303)
      expect(response.body).to eq('')

      expected_headers = {
        'Location' => my_presign
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end

    it 'redirects to presign url for the file - retry failure on pathname match' do
      mock_permissions_all(user_id, collection_id)

      request.session.merge!({ uid: user_id })
      allow(InvFile)
        .to receive(:joins)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        get(:presign, params: params)
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'redirects to presign url for the file - retry failure on object retreival' do
      mock_permissions_all(user_id, collection_id)

      request.session.merge!({ uid: user_id })
      allow_any_instance_of(InvFile)
        .to receive(:inv_version)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        get(:presign, params: params)
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'redirects to presign url for the file - retry version check' do
      mock_permissions_all(user_id, collection_id)

      request.session.merge!({ uid: user_id })
      allow_any_instance_of(Mysql2::Client)
        .to receive(:prepare)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        get(:presign, params: params)
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'redirects to presign url for the file - retry dua check' do
      mock_permissions_all(user_id, collection_id)

      request.session.merge!({ uid: user_id })
      allow_any_instance_of(InvObject)
        .to receive(:inv_duas)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        get(:presign, params: params)
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'test ark encoding recovery' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      m = %r{^(ark:)/(\d+)/([a-z0-9_]+)$}.match(object_ark)
      params2 = { object: m[1], file: "#{m[3]}/#{params[:version]}/#{params[:file]}", version: m[2].to_i }
      request.session.merge!({ uid: user_id })
      get(:presign, params: params2)
      expect(response.status).to eq(303)
      expect(response.body).to eq('')
    end

    it 'returns presign url for the file (no_redirect)' do
      mock_permissions_all(user_id, collection_id)

      params[:no_redirect] = true
      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to eq(my_presign)
    end

    it 'returns presign url for the file - space in filename' do
      pathname = 'producer/Caltrans EHE Tests.pdf'
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_download_size'] - 1
      inv_file.full_size = size_ok
      inv_file.pathname = pathname
      inv_file.save!

      params[:file] = pathname
      params[:no_redirect] = true
      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to eq(my_presign)
    end

    # The percent sign in a filename will fail... the UI must repair links before generating them
    it 'returns presign url for the file - percent in filename' do
      pathname = 'producer/Test %BF.pdf'

      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_download_size'] - 1
      inv_file.full_size = size_ok
      inv_file.pathname = pathname
      inv_file.save!

      params[:file] = pathname
      params[:no_redirect] = true
      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to eq(my_presign)
    end

    it 'redirects presign url for the file - contentDisposition=attachment' do
      mock_permissions_all(user_id, collection_id)

      params[:contentDisposition] = 'attachment'
      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type, contentDisposition: 'attachment' },
        {},
        follow_redirect: true
      ).and_return(mock_response(200, '', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(303)
      expect(response.headers['Location']).to eq(my_presign)
    end

    it 'returns 404 if presign url returns 404 - not found' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(404, 'File not found'))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(404)
    end

    it 'returns 404 if presign url returns 404 - file path not found' do
      mock_permissions_all(user_id, collection_id)

      params[:file] = 'non-existent.path'
      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(404)
    end

    it 'returns 403 if presign url not supported - Glacier' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(403, 'File is in offline storage, request is not supported'))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(403)
    end

    it 'returns 500 if presign url returns 500' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(500, 'System Error'))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(500)
    end

    it 'returns 408 if presign timeout' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_raise(
        HTTPClient::ReceiveTimeoutError
      )

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(408)
    end

    it 'redirects to download url when presign is unsupported' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        FileController.get_storage_presign_url(my_node_key_params(params), has_file: true),
        { contentType: inv_file.mime_type },
        {},
        follow_redirect: true
      ).and_return(mock_response(409, 'Redirecting to download URL', my_presign_wrapper))

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(303)
      expect(response.body).to eq('')

      expected_headers = {
        'Location' => inv_file.external_bytestream_uri.to_s
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end

  end

  describe ':storage_key' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, file: pathname }
    end

    it 'gets storage node and key for the file for a specific version' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = object.current_version.number
      request.session.merge!({ uid: user_id })
      get(
        :storage_key,
        params: @params
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(FileController.encode_storage_key(object_ark, @params[:version], @pathname))
    end

    it 'gets storage node and key for the file for version 0' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = 0
      request.session.merge!({ uid: user_id })
      get(
        :storage_key,
        params: @params
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(FileController.encode_storage_key(object_ark, object.current_version.number, @pathname))
    end

    it 'gets storage node and key for the file for a specific version 2' do
      ver = create(
        :inv_version,
        inv_object: object,
        ark: object_ark,
        number: object.current_version.number + 1,
        note: 'Sample Version 2'
      )

      @inv_file = create(
        :inv_file,
        inv_object: object,
        inv_version: ver,
        pathname: 'producer/foo.bin',
        mime_type: 'application/octet-stream',
        billable_size: 2000
      )
      mock_permissions_all(user_id, collection_id)

      @params[:version] = object.current_version.number + 1
      request.session.merge!({ uid: user_id })
      get(
        :storage_key,
        params: @params
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(FileController.encode_storage_key(ver.ark, ver.number, @pathname))
    end

    it 'gets 404 when requesting version 3' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = 3
      request.session.merge!({ uid: user_id })
      get(
        :storage_key,
        params: @params
      )
      expect(response.status).to eq(404)
    end

    it 'gets 404 when requesting non existent ark' do
      mock_permissions_all(user_id, collection_id)

      @params[:object] = 'ark:does-not-exist'
      @params[:version] = 1
      request.session.merge!({ uid: user_id })
      get(
        :storage_key,
        params: @params
      )
      expect(response.status).to eq(404)
    end

  end

end
