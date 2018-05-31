require 'rails_helper'

describe ObjectController do

  attr_reader :user_id

  attr_reader :collection
  attr_reader :collection_id
  attr_reader :objects

  attr_reader :object
  attr_reader :object_ark

  before(:each) do
    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)
    @objects = Array.new(3) {|i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}")}
    collection.inv_objects << objects

    @object_ark = objects[0].ark
    @object = objects[0]
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
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_download_size'])
      get(:download, {object: object_ark}, {uid: user_id})
      expect(response.status).to eq(403)
    end

    it "redirects to #{LostorageController} when sync download size exceeded" do
      mock_permissions_all(user_id, collection_id)
      allow_any_instance_of(InvObject).to receive(:total_actual_size).and_return(1 + APP_CONFIG['max_archive_size'])
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
    it 'prevents download without permissions'
    it "streams the object's producer files as a zipfile"
  end

  describe ':downloadManifest' do
    it 'prevents download without permissions'
    it 'streams the manifest as XML'
  end

  describe ':async' do
    it 'fails when object is too big for any download'
    it 'fails when object is too small for asynchronous download'
    it 'succeeds when object is the right size for synchronous download'
  end

  describe ':upload' do
    it 'redirects and displays an error when no file provided'
    it 'posts an update to the ingest service'
    it 'sets the batch ID for display'
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
      params = {
        receive_timeout: 7200,
        send_timeout: 3600,
        connect_timeout: 7200,
        keep_alive_timeout: 3600
      }
      client = double(HTTPClient)
      params.each do |param, value|
        writer = "#{param}=".to_sym
        expect(client).to receive(writer).with(value)
      end

      expect(HTTPClient).to receive(:new).and_return(client)
      result = controller.send(:mk_httpclient) # private method
      expect(result).to be(client)
    end
  end

end
