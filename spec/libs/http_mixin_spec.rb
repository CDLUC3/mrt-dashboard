require 'rails_helper'
require 'webmock/rspec'

class HttpStub
  include ::HttpMixin
end

describe HttpMixin do

  before(:each) do
    WebMock.disable_net_connect!
  end

  after(:each) do
    WebMock.allow_net_connect!
  end

  describe :mk_httpclient do
    it 'configures a client' do
      client = instance_double(HTTPClient)
      config = {
        receive_timeout: 7200,
        send_timeout: 3600,
        connect_timeout: 7200,
        keep_alive_timeout: 3600
      }
      config.each do |param, value|
        writer = "#{param}=".to_sym
        expect(client).to receive(writer).with(value)
      end
      expect(HTTPClient).to receive(:new).and_return(client)

      http = HttpStub.new
      expect(http.mk_httpclient).to eq(client)
    end
  end

  describe :http_post do
    attr_reader :stub

    before(:each) do
      @stub = HttpStub.new
    end

    it 'posts' do
      url = 'http://example.org'
      body = '👍'
      stub_request(:post, url).to_return(status: 200, body: body)
      res = stub.http_post(url)
      expect(res.status).to eq(200)
      expect(res.body).to eq(body)
    end

    it 'redirects' do
      url1 = 'http://example.org'
      url2 = 'http://example.edu'
      stub_request(:post, url1).to_return(status: 308, headers: { Location: url2 })
      body = '👍'
      stub_request(:post, url2).to_return(status: 200, body: body)
      res = stub.http_post(url1)
      expect(res.status).to eq(200)
      expect(res.body).to eq(body)
    end

    it 'fails if no location provided' do
      url = 'http://example.org/'
      stub_request(:post, url).to_return(status: 307)
      expect { stub.http_post(url) }.to raise_error(HTTPClient::BadResponseError)
    end

    it 'fails if max redirects exceeded' do
      url1 = 'http://example.org'
      url2 = 'http://example.edu'
      stub_request(:post, url1).to_return(status: 307, headers: { Location: url2 })
      stub_request(:post, url2).to_return(status: 308, headers: { Location: url1 }) # Loop
      expect { stub.http_post(url1) }.to raise_error(HTTPClient::BadResponseError)
    end
  end
end