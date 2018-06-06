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
end
