require 'rails_helper'

describe InvLocalid do
  attr_reader :obj
  attr_reader :owner

  before(:each) do
    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    @owner = obj.inv_owner
  end

  describe :new do
    it 'creates a localid' do
      id = 'foo'

      lid = InvLocalid.new(
        local_id: id,
        inv_object: obj,
        inv_owner: owner,
        created: Time.now
      )
      lid.save!

      actual = InvLocalid.find_by(local_id: id)
      expect(actual.id).to eq(lid.id)
    end
  end

end
