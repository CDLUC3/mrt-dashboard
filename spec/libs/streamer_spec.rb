require 'rails_helper'

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
      allow(client).to receive(:get_content).with(url)
        .and_yield('chunk 1')
        .and_yield('chunk 2')
        .and_yield('chunk 3')

      streamer = Streamer.new(url)
      yielded = []
      streamer.each { |chunk| yielded << chunk }
      expect(yielded).to eq(['chunk 1', 'chunk 2', 'chunk 3'])
    end
  end
end
