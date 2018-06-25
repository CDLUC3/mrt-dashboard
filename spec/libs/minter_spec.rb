require 'rails_helper'
require 'webmock/rspec'

module Noid
  describe Minter do
    attr_reader :noid_url

    before(:each) do
      WebMock.disable_net_connect!
      @noid_url = "http://example.org/"
    end

    it 'fetches an ID' do
      body = "id: 12345/ABCDE"
      stub_request(:get, "#{noid_url}?mint+1").to_return(body: body)

      minter = Minter.new(noid_url)
      actual = minter.mint
      expect(actual).to eq('ABCDE')
    end

    it 'respects the cache size parameter' do
      noids = ['ABC', 'DEF', 'GHI', 'JKL', 'MNO']
      count = noids.length

      body = noids.map { |noid| "id: 12345/#{noid}" }.join("\n")
      stub_request(:get, "#{noid_url}?mint+#{count}").to_return(body: body)

      minter = Minter.new(noid_url, count)
      noids.each do |expected|
        actual = minter.mint
        expect(actual).to eq(expected)
      end
    end

    it 'preserves Name Assigning Authority Numbers' do
      noids = ['123/ABC', '123/DEF', '123/GHI', '123/JKL', '123/MNO']
      count = noids.length

      body = noids.map { |noid| "id: #{noid}" }.join("\n")
      stub_request(:get, "#{noid_url}?mint+#{count}").to_return(body: body)

      minter = Minter.new(noid_url, count, true)
      noids.each do |expected|
        actual = minter.mint
        expect(actual).to eq(expected)
      end
    end

    it 'wraps SocketErrors' do
      minter = Minter.new(noid_url)
      stub_request(:get, "#{noid_url}?mint+1").to_raise(SocketError)
      expect { minter.mint }.to raise_error(Noid::MintException, 'Could not connect to server.')
    end

    it 'wraps other errors' do
      minter = Minter.new(noid_url)
      stub_request(:get, "#{noid_url}?mint+1").to_raise(StandardError)
      expect { minter.mint }.to raise_error(Noid::MintException, "Can't get ID; not a NOID server?")
    end

    it 'raises an exception for error responses' do
      minter = Minter.new(noid_url)
      stub_request(:get, "#{noid_url}?mint+1").to_return(body: 'nope', status: '403')
      expect { minter.mint }.to raise_error(Noid::MintException, 'Got error response from server.')
    end
  end
end
