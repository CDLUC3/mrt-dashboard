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

    @inv_file = create(
      :inv_file,
      inv_object: object,
      inv_version: object.current_version,
      pathname: 'producer/foo.bin',
      mime_type: 'application/octet-stream'
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

    def my_presign
      inv_file.bytestream_uri.to_s + '?presign=pretend'
    end

    def my_node_key(params)
      { 'node_id': 1111, 'key': params[:file] }.with_indifferent_access
    end

    def my_node_key_params(params)
      n = my_node_key(params)
      { node: n['node_id'], key: n['key'] }
    end

    def my_presign_wrapper
      {
        url: my_presign,
        expires: '2020-11-05T08:15:30-08:00'
      }.with_indifferent_access
    end

    def mock_response(status = 200, content = '')
      mockresp = instance_double(HTTP::Message)
      allow(mockresp).to receive(:status).and_return(status)
      allow(mockresp).to receive(:content).and_return(content)
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
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_node_key(params).to_json))

      expect(client).to receive(:get).with(
        APP_CONFIG['storage_presign_file'],
        my_node_key_params(params),
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_presign_wrapper.to_json))

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

    it 'redirects request for FILENAME WITH SPACES to presign url for the file' do
      pathname = 'producer/AIP/Subseries 1.1/Objects/Evolution book/Tate Collection |landscape2'
      mock_permissions_all(user_id, collection_id)

      inv_file.pathname = pathname
      inv_file.save!

      params[:file] = pathname

      expect(client).to receive(:get).with(
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_node_key(params).to_json))

      expect(client).to receive(:get).with(
        APP_CONFIG['storage_presign_file'],
        my_node_key_params(params),
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_presign_wrapper.to_json))

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

    it 'redirects request for FILENAME WITH SPACES AND PIPES to presign url for the file' do
      pathname = 'producer/AIP/Subseries 1.1/Objects/Evolution book/Tate Collection |landscape2'
      mock_permissions_all(user_id, collection_id)

      inv_file.pathname = pathname
      inv_file.save!

      params[:file] = pathname

      expect(client).to receive(:get).with(
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_node_key(params).to_json))

      expect(client).to receive(:get).with(
        APP_CONFIG['storage_presign_file'],
        my_node_key_params(params),
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_presign_wrapper.to_json))

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

    it 'returns 404 if presign lookup fails' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(404))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(404)
    end

    it 'returns 404 if presign url creation fails' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_node_key(params).to_json))

      expect(client).to receive(:get).with(
        APP_CONFIG['storage_presign_file'],
        my_node_key_params(params),
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(404))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(404)
    end

    it 'redirects to download url when presign is unsupported' do
      mock_permissions_all(user_id, collection_id)

      expect(client).to receive(:get).with(
        APP_CONFIG['inventory_presign_file'],
        params,
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(200, my_node_key(params).to_json))

      expect(client).to receive(:get).with(
        APP_CONFIG['storage_presign_file'],
        my_node_key_params(params),
        { 'Accept' => 'application/json' }
      ).and_return(mock_response(409, my_presign_wrapper.to_json))

      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(303)
      expect(response.body).to eq('')

      expected_headers = {
        'Location' => inv_file.bytestream_uri.to_s
      }
      response_headers = response.headers
      expected_headers.each do |header, value|
        expect(response_headers[header]).to eq(value)
      end
    end

  end

end
