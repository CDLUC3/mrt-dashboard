require 'rails_helper'

describe InvEmbargo do
  attr_reader :obj
  attr_reader :embargo

  before(:each) do
    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    @embargo = create(:inv_embargo, inv_object: obj)
  end

  describe ':in_embargo?' do
    it 'is true when embargo date is in the future' do
      embargo.embargo_end_date = DateTime.now.utc + 1.hours
      expect(embargo.in_embargo?).to eq(true)
    end
    it 'is false when embargo date is in the past' do
      embargo.embargo_end_date = DateTime.now.utc - 1.hours
      expect(embargo.in_embargo?).to eq(false)
    end
  end
end
