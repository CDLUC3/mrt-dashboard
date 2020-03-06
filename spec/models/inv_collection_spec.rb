require 'rails_helper'

describe InvCollection do
  attr_reader :collection

  before(:each) do
    @collection = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
  end

  describe :to_param do
    it 'encodes the ark' do
      encoded_ark = Encoder.urlencode(collection.ark)
      expect(collection.to_param).to eq(encoded_ark)
    end
  end
end
