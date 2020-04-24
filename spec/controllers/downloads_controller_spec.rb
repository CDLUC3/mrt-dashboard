require 'rails_helper'
require 'support/presigned'

RSpec.describe DownloadsController, type: :controller do
  describe ':downloads' do

    before(:each) do
      @client = mock_httpclient
    end

    it 'add token to page' do
      get 'add', token: 'aaa'
      expect(response.status).to eq(200)
      expect(request.fullpath).to eq('/downloads/add/aaa')
    end

    it 'add without token' do
      get 'add'
      expect(response.status).to eq(200)
      expect(request.fullpath).to eq('/downloads/add')
    end

    it 'check a token' do
      token = SecureRandom.uuid
      presign = 'https://foo.bar'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {},
        {},
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
      get 'get', token: token
      expect(response.status).to eq(303)
      expect(response.headers['Location']).to eq(presign)
    end

    it 'check a token with no_redirect' do
      token = SecureRandom.uuid
      presign = 'https://foo.bar'
      expect(@client).to receive(:get).with(
        File.join(APP_CONFIG['storage_presign_token'], token),
        {},
        {},
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
      get 'get', token: token, no_redirect: 1
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to eq(presign)
    end
  end
end
