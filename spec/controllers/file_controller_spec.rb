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
  end
end
