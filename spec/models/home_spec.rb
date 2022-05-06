require 'rails_helper'

describe Home do

  describe :to_param do
    it 'check audit_replic stats' do
      expect(Home.audit_replic_stats.length).to eq(4)
    end
  end
end
