require 'rails_helper'
require 'webmock/rspec'

describe Streamer do
  describe ':each' do
    it 'yields the chunks returned by the HTTPClient' do
      url = 'http://example.org/stream.bin'
      client = instance_double(HTTPClient)
      {
        receive_timeout: 7200,
        send_timeout: 3600,
        connect_timeout: 7200,
        keep_alive_timeout: 3600
      }.each do |param, value|
        writer = "#{param}=".to_sym
        allow(client).to receive(writer).with(value)
      end
      allow(HTTPClient).to receive(:new).and_return(client)
      uri = URI.parse(url)
      allow(client).to receive(:get_content).with(uri)
        .and_yield('chunk 1')
        .and_yield('chunk 2')
        .and_yield('chunk 3')

      streamer = Streamer.new(url)
      yielded = []
      streamer.each { |chunk| yielded << chunk }
      expect(yielded).to eq(['chunk 1', 'chunk 2', 'chunk 3'])
    end
  end

  describe ':new' do
    before(:each) do
      WebMock.disable_net_connect!
    end

    it 'disallows spaces in URLs' do
      url = 'http://store01-aws.cdlib.org:35221/content/5001/ark:%2F13030%2Fm5kh22mg/2/producer%2FCaltrans EHE Tests.pdf'
      expect { Streamer.new(url) }.to raise_error(URI::InvalidURIError, "bad URI(is not URI?): #{url}")
    end

    after(:each) do
      WebMock.allow_net_connect!
    end
  end
end
