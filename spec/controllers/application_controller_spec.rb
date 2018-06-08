require 'rails_helper'

describe ApplicationController do
  describe ':in_embargo?' do
    attr_reader :user_id

    attr_reader :collection
    attr_reader :collection_id

    attr_reader :obj
    attr_reader :embargo

    before(:each) do
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

      @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
      @collection_id = mock_ldap_for_collection(collection)

      @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
      collection.inv_objects << obj

      @embargo = create(:inv_embargo, inv_object: obj)
    end

    it 'is true when embargo date is in the future' do
      embargo.embargo_end_date = DateTime.now.utc + 1.hours
      expect(controller.in_embargo?(obj)).to eq(true)
    end

    it 'is false when embargo date is in the past' do
      embargo.embargo_end_date = DateTime.now.utc - 1.hours
      expect(controller.in_embargo?(obj)).to eq(false)
    end

    it 'is false when user has admin permission' do
      mock_permissions_all(user_id, collection_id)
      allow(controller).to receive(:current_uid).and_return(user_id)

      embargo.embargo_end_date = DateTime.now.utc + 1.hours
      expect(controller.in_embargo?(obj)).to eq(false)
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
        12345 => '12.3 KB',
        1234567 => '1.2 MB',
        1234567890 => '1.2 GB',
        1234567890123 => '1.2 TB'
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
        12345 => '12.35 KB', # 12.345 rounds up to 12.35
        1234567 => '1.23 MB',
        1234567890 => '1.23 GB',
        1234567890123 => '1.23 TB'
      }.each do |i, expected|
        actual = controller.send(:number_to_storage_size, i, 2)
        expect(actual).to eq(expected)
      end
    end
  end
end
