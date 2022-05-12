require 'rails_helper'

describe Home do

  describe :to_param do
    it 'check audit_replic stats' do
      datestr = 'INTERVAL -15 MINUTE'
      expect(Home.audit_replic_stats(datestr).length).to eq(4)
    end
  end
end
