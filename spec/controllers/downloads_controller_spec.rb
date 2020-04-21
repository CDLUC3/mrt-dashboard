require 'rails_helper'

RSpec.describe DownloadsController, type: :controller do
  describe ':downloads' do

    it 'add token to page' do
      get 'add', token: 'aaa'
      expect(response.status).to eq(200)
      expect(request.fullpath).to eq('/downloads/add/aaa')
    end

    it 'check a token' do
      get 'get', token: 'aaa'
      expect(response.status).to eq(302)
      expect(request.fullpath).to eq('/downloads/get/aaa')
    end

    it 'check a token mocked as available' do
      get 'get', token: 'aaa', available: 'true'
      expect(response.status).to eq(302)
    end
  end
end
