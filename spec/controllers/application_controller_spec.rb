require 'rails_helper'

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
end
