require 'rails_helper'

describe InvObject do
  attr_reader :obj
  attr_reader :collection

  before(:each) do
    @collection = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    collection.inv_objects << obj
  end

  describe :bytestream_uri do
    it 'generates the "uri_1" (content) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_1']}#{obj.node_number}/#{obj.to_param}"
      expect(obj.bytestream_uri).to eq(URI.parse(expected_uri))
    end
  end

  describe :bytestream_uri_2 do
    it 'generates the "uri_2" (producer) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_2']}#{obj.node_number}/#{obj.to_param}"
      expect(obj.bytestream_uri2).to eq(URI.parse(expected_uri))
    end
  end

  describe :bytestream_uri_3 do
    it 'generates the "uri_3" (manifest) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_3']}#{obj.node_number}/#{obj.to_param}"
      expect(obj.bytestream_uri3).to eq(URI.parse(expected_uri))
    end
  end

end
