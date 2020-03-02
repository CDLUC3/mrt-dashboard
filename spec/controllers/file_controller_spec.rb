require 'rails_helper'

describe FileController do

  attr_reader :user_id
  attr_reader :collection
  attr_reader :collection_id

  attr_reader :object
  attr_reader :object_ark

  attr_reader :inv_file
  attr_reader :pathname
  attr_reader :basename
  attr_reader :client

  def mock_httpclient
    client = instance_double(HTTPClient)
    allow(client).to receive(:follow_redirect_count).and_return(10)
    %i[receive_timeout= send_timeout= connect_timeout= keep_alive_timeout=].each do |m|
      allow(client).to receive(m)
    end
    allow(HTTPClient).to receive(:new).and_return(client)
    client
  end

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
      get(:download, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:download, params, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)

      size_too_large = 1 + APP_CONFIG['max_download_size']
      inv_file.full_size = size_too_large
      inv_file.save!

      get(:download, params, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it 'streams the file' do
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_download_size'] - 1
      inv_file.full_size = size_ok
      inv_file.save!

      streamer = double(Streamer)
      expected_url = inv_file.bytestream_uri
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:download, params, { uid: user_id })

      expect(response.status).to eq(200)

      expected_headers = {
        'Content-Type' => inv_file.mime_type,
        'Content-Disposition' => "inline; filename=\"#{basename}\"",
        'Content-Length' => inv_file.full_size.to_s
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end

    it 'handles filenames with spaces' do
      pathname = 'producer/Caltrans EHE Tests.pdf'
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_download_size'] - 1
      inv_file.full_size = size_ok
      inv_file.pathname = pathname
      inv_file.save!

      streamer = double(Streamer)
      expected_url = inv_file.bytestream_uri
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      params[:file] = pathname
      get(:download, params, { uid: user_id })
      expect(response.status).to eq(200)
    end

    it 'handles filenames with spaces and pipes' do
      pathname = 'producer/AIP/Subseries 1.1/Objects/Evolution book/Tate Collection |landscape2'
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_download_size'] - 1
      inv_file.full_size = size_ok
      inv_file.pathname = pathname
      inv_file.save!

      streamer = double(Streamer)
      expected_url = inv_file.bytestream_uri
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      params[:file] = pathname
      get(:download, params, { uid: user_id })
      expect(response.status).to eq(200)
    end
  end

  describe ':presign' do
    attr_reader :params

    def get_storage_presign_url(obj)
      "#{APP_CONFIG['storage_presign_file']}#{obj[:node_id]}/#{obj[:key]}"
    end

    def my_presign
      inv_file.bytestream_uri.to_s + '?presign=pretend'
    end

    def my_node_key_params(params)
      r = get(:storage_key, params, { uid: user_id })
      json = JSON.parse(r.body)
      {
        node_id: json['node_id'],
        key: json['key']
      }
    end

    def my_presign_wrapper
      {
        status: 200,
        url: my_presign,
        expires: '2020-11-05T08:15:30-08:00',
        message: 'Presigned URL created'
      }.with_indifferent_access
    end

    def mock_response(status = 200, message = '', json = {})
      json['status'] = status
      json['message'] = message
      mockresp = instance_double(HTTP::Message)
      allow(mockresp).to receive(:status).and_return(status)
      allow(mockresp).to receive(:content).and_return(json.to_json)
      mockresp
    end

    before(:each) do
      @params = { object: object_ark, file: pathname, version: object.current_version.number }
    end

    it 'requires a login' do
      get(:presign, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents presign without permissions' do
      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'redirects to presign url for the file' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        get_storage_presign_url(my_node_key_params(params)),
        {},
        {}
      ).and_return(mock_response(200, '', my_presign_wrapper))

      get(:presign, params, { uid: user_id })
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

    it 'returns 404 if presign url returns 404 - not found' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        get_storage_presign_url(my_node_key_params(params)),
        {},
        {}
      ).and_return(mock_response(404, 'File not found'))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(404)
      json = JSON.parse(response.body)
      expect(json['status']).to eq(response.status)
      expect(json['message']).to eq('File not found')
    end

    it 'returns 403 if presign url not supported - Glacier' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        get_storage_presign_url(my_node_key_params(params)),
        {},
        {}
      ).and_return(mock_response(403, 'File is in offline storage, request is not supported'))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(403)
      json = JSON.parse(response.body)
      expect(json['status']).to eq(response.status)
      expect(json['message']).to eq('File is in offline storage, request is not supported')
    end

    it 'returns 500 if presign url returns 500' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        get_storage_presign_url(my_node_key_params(params)),
        {},
        {}
      ).and_return(mock_response(500, 'System Error'))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(500)
      json = JSON.parse(response.body)
      expect(json['status']).to eq(response.status)
      expect(json['message']).to eq('System Error')
    end

    it 'redirects to download url when presign is unsupported' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        get_storage_presign_url(my_node_key_params(params)),
        {},
        {}
      ).and_return(mock_response(409, 'Redirecting to download URL', my_presign_wrapper))

      get(:presign, params, { uid: user_id })
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

    def build_storage_key(ark, version, file)
      "#{ark}|#{version}|#{file}"
    end

    def encode_storage_key(ark, version, file)
      ERB::Util.url_encode(build_storage_key(ark, version, file))
    end

    before(:each) do
      @params = { object: object_ark, file: pathname }
    end

    it 'gets storage node and key for the file for a specific version' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = object.current_version.number
      get(
        :storage_key,
        @params,
        { uid: user_id }
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(encode_storage_key(object_ark,  @params[:version], @pathname))
    end

    it 'gets storage node and key for the file for version 0' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = 0
      get(
        :storage_key,
        @params,
        { uid: user_id }
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(encode_storage_key(object_ark,  object.current_version.number, @pathname))
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
      get(
        :storage_key,
        @params,
        { uid: user_id }
      )
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['node_id']).to eq(9999)
      expect(json['key']).to eq(encode_storage_key(ver.ark,  ver.number, @pathname))
    end

    it 'gets 404 when requesting version 3' do
      mock_permissions_all(user_id, collection_id)

      @params[:version] = 3
      get(
        :storage_key,
        @params,
        { uid: user_id }
      )
      expect(response.status).to eq(404)
    end

    it 'gets 404 when requesting non existent ark' do
      mock_permissions_all(user_id, collection_id)

      @params[:object] = 'ark:does-not-exist'
      @params[:version] = 1
      get(
        :storage_key,
        @params,
        { uid: user_id }
      )
      expect(response.status).to eq(404)
    end
  end

end
