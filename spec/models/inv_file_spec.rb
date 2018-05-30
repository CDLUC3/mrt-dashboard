require 'rails_helper'

describe InvFile do
  attr_accessor :obj, :version, :file

  before(:each) do
    inv_collection_1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    inv_collection_1.inv_objects << obj
    @version = obj.current_version
    @file = create(
      :inv_file,
      inv_object: obj,
      inv_version: version,
      pathname: "producer/file-1.bin",
      full_size: 1024,
      billable_size: 1024,
      mime_type: 'application/octet-stream'
    )
  end

  describe :bytestream_uri do
    it 'generates the "uri_1" (content) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_1']}#{obj.node_number}/#{obj.to_param}/#{version.to_param}/#{file.to_param}"
      expect(file.bytestream_uri).to eq(URI.parse(expected_uri))
    end
  end
end
