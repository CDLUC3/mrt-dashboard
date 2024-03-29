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

    it 'total actual size - retry error' do
      mock_permissions_all(user_id, collection_id)

      request.session.merge!({ uid: user_id })
      allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
        .to receive(:sum)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        get(:download, params: params)
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)

      size_too_large = 1 + APP_CONFIG['max_download_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      request.session.merge!({ uid: user_id })
      get(:download, params: params)
      expect(response.status).to eq(403)
    end

    it 'returns 413 when sync download size exceeded' do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_archive_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      request.session.merge!({ uid: user_id })
      get(:download, params: params)
      expect(response.status).to eq(413)
    end

    it 'streams the version as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_archive_size'] - 1
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_ok)

      streamer = double(Streamer)
      expected_url = "#{version.bytestream_uri}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      request.session.merge!({ uid: user_id })
      get(:download, params: params)

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
      request.session.merge!({ uid: nil })
      get(:presign, params: params)
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
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

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
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

      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      json = JSON.parse(response.body)
      expect(json['token']).to eq('aaa')
    end

    it 'request async assembly of a non-existing version of an object' do
      mock_permissions_all(user_id, collection_id)
      params[:version] = 3
      request.session.merge!({ uid: user_id })
      get(:presign, params: params)
      expect(response.status).to eq(404)
    end
  end

  describe ':download_user' do
    attr_reader :params

    before(:each) do
      @params = { object: object_ark, version: version.number }
    end

    it 'requires a login' do
      request.session.merge!({ uid: nil })
      get(:download_user, params: params)
      expect(response.status).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'prevents download without permissions' do
      request.session.merge!({ uid: user_id })
      get(:download_user, params: params)
      expect(response.status).to eq(401)
    end

    it 'prevents download when download size exceeded' do
      mock_permissions_all(user_id, collection_id)

      size_too_large = 1 + APP_CONFIG['max_download_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      request.session.merge!({ uid: user_id })
      get(:download_user, params: params)
      expect(response.status).to eq(403)
    end

    it 'returns 413 when sync download size exceeded' do
      mock_permissions_all(user_id, collection_id)
      size_too_large = 1 + APP_CONFIG['max_archive_size']
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_too_large)
      request.session.merge!({ uid: user_id })
      get(:download_user, params: params)
      expect(response.status).to eq(413)
    end

    it 'streams the version as a zipfile' do
      mock_permissions_all(user_id, collection_id)

      size_ok = APP_CONFIG['max_archive_size'] - 1
      allow_any_instance_of(InvVersion).to receive(:total_actual_size).and_return(size_ok)

      streamer = double(Streamer)
      expected_url = "#{version.bytestream_uri2}?t=zip"
      allow(Streamer).to receive(:new).with(expected_url).and_return(streamer)

      request.session.merge!({ uid: user_id })
      get(:download_user, params: params)

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
end
