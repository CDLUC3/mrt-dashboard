require 'rails_helper'
require 'securerandom'
require 'support/presigned'

describe ApplicationController do

  describe ':redirect_to_latest_version' do
    # TODO: why is this a good thing?
    it 'sets latest version to blank if no object found' do
      params = controller.params
      params[:object] = 'I am definitely not an object'
      allow(InvObject).to receive(:find_by_ark).with(any_args).and_return(nil)
      controller.send(:redirect_to_latest_version)
      expect(params[:version]).to eq(nil.to_s)
    end
  end

  describe ':available_groups' do
    attr_reader :user_id

    before(:each) do
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')
      controller.session[:uid] = user_id
    end

    it 'returns [] if no groups' do
      groups = controller.send(:available_groups)
      expect(groups).to eq([])
    end

    it 'returns each group as a hash' do
      collections = Array.new(3) do |i|
        collection = create(:private_collection, name: "Collection #{i}", mnemonic: "collection #{i}")
        mock_ldap_for_collection(collection)
        collection
      end
      mock_permissions_all(user_id, collections.map(&:mnemonic))

      groups = controller.send(:available_groups)
      expect(groups.size).to eq(collections.size)
      collections.each_with_index do |collection, i|
        group = groups[i]
        expect(group[:id]).to eq(collection.mnemonic)
        expect(group[:description]).to eq(collection.name)
        expect(group[:user_permissions]).to eq(PERMISSIONS_ALL)
      end
    end
  end

  describe ':current_user' do
    attr_reader :user_id
    attr_reader :password
    attr_reader :user

    before(:each) do
      @user_id = 'jdoe'
      @password = 'correcthorsebatterystaple'
      @user = double(User)
      allow(User).to receive(:find_by_id).with(nil).and_return(nil)
      allow(User).to receive(:find_by_id).with(user_id).and_return(user)
    end

    it 'reads the user ID from the session' do
      controller.session[:uid] = user_id
      expect(controller.send(:current_user)).to eq(user)
    end

    it 'reads the user ID from basic auth' do
      controller.request.headers['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64("#{user_id}:#{password}")}".strip
      expect(User).to receive(:valid_ldap_credentials?).with(user_id, password).and_return(true)
      expect(controller.send(:current_user)).to eq(user)
    end

    it 'returns nil for bad auth' do
      controller.request.headers['HTTP_AUTHORIZATION'] = 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==' # from RFC7617
      expect(User).to receive(:valid_ldap_credentials?).with('Aladdin', 'open sesame').and_return(false)
      expect(controller.send(:current_user)).to be_nil
    end
  end

  describe ':render_unavailable' do
    it 'returns a 500 error' do
      get(:render_unavailable)
      expect(response.status).to eq(500)
    end
  end

  describe ':number_to_storage_size' do
    it 'defaults to one digit after the decimal' do
      {
        0 => '0 B',
        1 => '1 Byte',
        123 => '123 B',
        1234 => '1.2 KB',
        12_345 => '12.3 KB',
        1_234_567 => '1.2 MB',
        1_234_567_890 => '1.2 GB',
        1_234_567_890_123 => '1.2 TB'
      }.each do |i, expected|
        actual = controller.send(:number_to_storage_size, i)
        expect(actual).to eq(expected)
      end
    end

    it 'supports multiple digits after the decimal' do
      {
        0 => '0 B',
        1 => '1 Byte',
        123 => '123 B',
        1234 => '1.23 KB',
        12_345 => '12.34 KB', # as of Ruby 2.4, 12.345 rounds down to 12.34
        1_234_567 => '1.23 MB',
        1_234_567_890 => '1.23 GB',
        1_234_567_890_123 => '1.23 TB'
      }.each do |i, expected|
        actual = controller.send(:number_to_storage_size, i, 2)
        expect(actual).to eq(expected)
      end
    end

    it 'returns nil for nil' do
      actual = controller.send(:number_to_storage_size, nil)
      expect(actual).to be_nil
    end

    it 'returns nil for bad arguments' do
      actual = controller.send(:number_to_storage_size, 'I am definitely not a number')
      expect(actual).to be_nil
    end

  end

  describe ':max_download_size_pretty' do
    it 'formats the max download size' do
      size = APP_CONFIG['max_download_size']
      expected = controller.send(:number_to_storage_size, size)
      actual = controller.send(:max_download_size_pretty)
      expect(actual).to eq(expected)
    end
  end

  describe ':is_ark?' do
    it 'matches an ARK' do
      good_arks = [
        'ark:/13030/m54f6mfn',
        'ark:/a3030/m54f6mfn',
        'ark:/Z3030/m54f6mfn',
        'http://n2t.net/ark:/13030/m54f6mfn'
      ]

      good_arks.each do |ark|
        expect(controller.send(:is_ark?, ark)).to eq(true), "#{ark} should be an ARK"
      end
    end

    it "doesn't match something that looks like an ARK but isn't" do
      bad_arks = [
        'doi:/13030/m54f6mfn',
        'ark:/13030',
        'ark:/13030/',
        'ark:13030/m54f6mfn',
        'ark:13030m54f6mfn',
        'ark:/13030m54f6mfn',
        'ark:/az0303/m54f6mfn',
        'ark:/aZ0303/m54f6mfn',
        'ark:/Az0303/m54f6mfn',
        'ark:/AZ0303/m54f6mfn',
        'ark:/0303/m54f6mfn',
        'ark:/a303/m54f6mfn'
      ]

      bad_arks.each do |bad_ark|
        expect(controller.send(:is_ark?, bad_ark)).to eq(false), "#{bad_ark} should not be an ARK"
      end
    end
  end

  describe ':url_string_with_proto' do
    it 'verify unchanged url' do
      host = 'foo.bar'
      http_req = "http://#{host}"
      expect(controller.send(:url_string_with_proto, http_req)).to eq(http_req), 'Location should be unmodified'
    end

    it 'verify https replacement in url' do
      host = 'foo.bar'
      http_req = "http://#{host}"
      https_req = "https://#{host}"
      # For testing purposes, simulate APP_CONFIG['proto_force'] == 'https'
      expect(controller.send(:url_string_with_proto, http_req, force_https: true)).to eq(https_req), 'Location should start with https'
    end

    it 'catch encoding error in url' do
      host = 'foo.bar'
      https_req = "https://#{host}/api/presign-file/ark:/13030/m5sf7w9f/1/producer/Peuß%20Dryad%20raw%20data.xlsx?no_redirect=true"
      err = "Url format error caught: #{https_req}"

      expect(Rails.logger).to receive(:error).with(err)
      expect(controller.send(:url_string_with_proto, https_req, force_https: true)).not_to eq(https_req), 'Expect encoding error for URL'
    end
  end

  describe ':stream_response' do
    before(:each) do
      WebMock.disable_net_connect!
    end

    skip it 'disallows spaces in URLs' do
      url = 'http://store01-aws.cdlib.org:35221/content/5001/ark:%2F13030%2Fm5kh22mg/2/producer%2FCaltrans EHE Tests.pdf'
      expect do
        controller.send(:stream_response, url, 'inline', 'Caltrans EHE Tests.pdf', 'text/pdf', 5_354_848)
      end.to raise_error(URI::InvalidURIError, /bad URI\(is not URI\?\)/)
    end

    after(:each) do
      WebMock.allow_net_connect!
    end
  end

  describe 'Rack::Response.close' do
    it "doesn't close a non-closeable body" do
      response = Rack::Response.new
      body = response.instance_variable_get(:@body)
      # if we're not explicit about this, the not_to expectation will actually make it return true
      allow(body).to receive(:respond_to?).with(:close).and_return(false)
      expect(body).not_to receive(:close)
      response.close
    end

    it 'closes a closeable body' do
      response = Rack::Response.new
      body = response.instance_variable_get(:@body)
      # probably not needed because the expectation would take care of it, but let's be explicit
      allow(body).to receive(:respond_to?).with(:close).and_return(true)
      expect(body).to receive(:close)
      response.close
    end
  end

  describe 'assemble / presign url construction' do
    before(:each) do
      @ark = 'ark:/99999/abc'
      @arkenc = 'ark%3A%2F99999%2Fabc'
      @ver = 2
      @path = 'foo bar.doc'
      @client = mock_httpclient
    end

    def mock_httpclient
      client = instance_double(HTTPClient)
      allow(client).to receive(:follow_redirect_count).and_return(10)
      %i[receive_timeout= send_timeout= connect_timeout= keep_alive_timeout=].each do |m|
        allow(client).to receive(m)
      end
      allow(HTTPClient).to receive(:new).and_return(client)
      client
    end

    it 'build_storage_key(ark, version, file)' do
      key = ApplicationController.build_storage_key(@ark, @ver, @path)
      expect(key).to eq("#{@ark}|#{@ver}|#{@path}")
    end

    it 'build_storage_key(ark, version)' do
      key = ApplicationController.build_storage_key(@ark, @ver)
      expect(key).to eq("#{@ark}|#{@ver}")
    end

    it 'build_storage_key(ark)' do
      key = ApplicationController.build_storage_key(@ark)
      expect(key).to eq(@ark)
    end

    it 'encode_storage_key' do
      enckey = ApplicationController.encode_storage_key(@ark)
      expect(enckey).to eq(@arkenc)
    end

    it 'get_storage_presign_url does not contain //' do
      nk = { node_id: 9999, key: @arkenc }
      url = ApplicationController.get_storage_presign_url(nk)
      expect(url).not_to match('https?://.*//.*')
    end

    it 'get_storage_presign_url(nodekey, has_file: true)' do
      key = ApplicationController.build_storage_key(@ark, @ver, @path)
      enckey = ApplicationController.encode_storage_key(key)
      nk = { node_id: 9999, key: enckey }
      url = ApplicationController.get_storage_presign_url(nk, has_file: true)
      expect(url).to match('.*/presign-file/.*')
    end

    it 'get_storage_presign_url(nodekey, has_file: false)' do
      key = ApplicationController.build_storage_key(@ark, @ver)
      enckey = ApplicationController.encode_storage_key(key)
      nk = { node_id: 9999, key: enckey }
      url = ApplicationController.get_storage_presign_url(nk, has_file: false)
      expect(url).to match(".*/assemble-obj/9999/#{enckey}")
    end

    # This test illustrates the return object, it does not perform any meaningful check since the mock constructs the return object
    it 'presign_obj_by_token 200' do
      token = SecureRandom.uuid
      presign = 'https://presign.example'
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_return(
        mock_response(
          200,
          'Object is available',
          {
            token: token,
            'anticipated-size': 12_345,
            url: presign
          }
        )
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename })
      expect(response.status).to eq(303)
      expect(response.headers['Location']).to eq(presign)
    end

    it 'presign_obj_by_token with no_redirect 200' do
      token = SecureRandom.uuid
      presign = 'https://presign.example'
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_return(
        mock_response(
          200,
          'Object is available',
          {
            token: token,
            'anticipated-size': 12_345,
            url: presign
          }
        )
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename, no_redirect: 1 })
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to eq(presign)
    end

    # This test illustrates the return object, it does not perform any meaningful check since the mock constructs the return object
    it 'presign_obj_by_token 202' do
      token = SecureRandom.uuid
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_return(
        mock_response(
          202,
          'Object is not ready',
          {
            token: token,
            'anticipated-size': 12_345,
            'anticipated-availability-time': '2009-06-15T13:45:30'
          }
        )
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename })
      expect(response.status).to eq(202)
    end

    # This test illustrates the return object, it does not perform any meaningful check since the mock constructs the return object
    it 'presign_obj_by_token 404' do
      token = SecureRandom.uuid
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_return(
        mock_response(
          404,
          'Object not found'
        )
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename })
      expect(response.status).to eq(404)
    end

    # This test illustrates the return object, it does not perform any meaningful check since the mock constructs the return object
    it 'presign_obj_by_token 500' do
      token = SecureRandom.uuid
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_return(
        mock_response(
          500,
          'error message'
        )
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename })
      expect(response.status).to eq(500)
    end

    it 'presign_obj_by_token simulate timeout - returns 202' do
      token = SecureRandom.uuid
      filename = 'object.zip'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {
          timeout: 6 * 60,
          contentDisposition: "attachment; filename=#{filename}"
        },
        follow_redirect: true
      ).and_raise(
        HTTPClient::ReceiveTimeoutError
      )
      get(:presign_obj_by_token, params: { token: token, filename: filename })
      expect(response.status).to eq(202)
    end
  end
end
