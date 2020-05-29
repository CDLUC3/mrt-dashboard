require 'rails_helper'
require 'support/presigned'

RSpec.describe VersionController, type: :controller do
  attr_reader :user_id
  attr_reader :collection
  attr_reader :collection_id

  attr_reader :object
  attr_reader :object_ark

  attr_reader :version

  attr_reader :client

  before(:each) do
    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)

    @object = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    collection.inv_objects << object
    @object_ark = object.ark
    object.current_version.ark = @object_ark
    object.current_version.save!

    @version = object.current_version

    @client = mock_httpclient
  end

  describe ':download' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, version: version.number }
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
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      get(:download, params, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it "redirects to #{LostorageController} when sync download size exceeded" do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_archive_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      get(:download, params, { uid: user_id })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('lostorage')
    end

    it 'streams the version as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_archive_size'] - 1
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_ok)

      streamer = double(Streamer)
      expected_url = "#{version.bytestream_uri}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:download, params, { uid: user_id })

      expect(response.status).to eq(200)

      expected_filename = "#{Orchard::Pairtree.encode(object_ark)}_version_#{version.number}.zip"
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

      ver = create(
        :inv_version,
        inv_object: object,
        ark: object_ark,
        number: object.current_version.number + 1,
        note: 'Sample Version 2'
      )
      ver.save!
      @params = { object: object_ark, version: ver.number }
    end

    it 'requires a login' do
      get(:presign, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'request async assembly of the current version of an object' do
      mock_permissions_all(user_id, collection_id)

      params[:version] = 2
      mock_assembly(
        @object.node_number,
        ApplicationController.encode_storage_key(@object.ark, params[:version]),
        response_assembly_200('aaa')
      )

      get(:presign, params, { uid: user_id })
      json = JSON.parse(response.body)
      expect(json['token']).to eq('aaa')
    end

    it 'request async assembly of a past version of an object' do
      mock_permissions_all(user_id, collection_id)
      params[:version] = 1
      mock_assembly(
        @object.node_number,
        ApplicationController.encode_storage_key(@object.ark, params[:version]),
        response_assembly_200('aaa')
      )

      get(:presign, params, { uid: user_id })
      json = JSON.parse(response.body)
      expect(json['token']).to eq('aaa')
    end

    it 'request async assembly of a non-existing version of an object' do
      mock_permissions_all(user_id, collection_id)
      params[:version] = 3
      get(:presign, params, { uid: user_id })
      expect(response.status).to eq(404)
    end
  end

  describe ':download_user' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, version: version.number }
    end

    it 'requires a login' do
      get(:download_user, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      get(:download_user, params, { uid: user_id })
      expect(response.status).to eq(401)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)

      size_too_large = 1 + APP_CONFIG['max_download_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      get(:download_user, params, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it "redirects to #{LostorageController} when sync download size exceeded" do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_archive_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      get(:download_user, params, { uid: user_id })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('lostorage')
    end

    it 'streams the version as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_archive_size'] - 1
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_ok)

      streamer = double(Streamer)
      expected_url = "#{version.bytestream_uri2}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      get(:download_user, params, { uid: user_id })

      expect(response.status).to eq(200)

      expected_filename = "#{Orchard::Pairtree.encode(object_ark)}_version_#{version.number}.zip"
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

  describe ':async' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, version: version.number }
    end

    it 'requires a login' do
      get(:async, params, { uid: nil })
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'fails when object is too big for any download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_download_size'])
      get(:async, params, { uid: user_id })
      expect(response.status).to eq(403)
    end

    it 'fails when object is too small for asynchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(APP_CONFIG['max_archive_size'] - 1)
      get(:async, params, { uid: user_id })
      expect(response.status).to eq(406)
    end

    it 'succeeds when object is the right size for synchronous download' do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_archive_size'])
      get(:async, params, { uid: user_id })
      expect(response.status).to eq(200)
    end
  end

end
