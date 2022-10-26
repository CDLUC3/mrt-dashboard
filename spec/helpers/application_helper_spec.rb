# require 'rails_helper'

describe ApplicationHelper do
  describe ':formatted_int' do
    it 'puts commas into ints > 1000' do
      include ApplicationHelper
      an_int = 1_000_000
      expected_str = '1,000,000'
      expect(formatted_int(an_int)).to eq(expected_str)
    end
  end

  describe ':show_environment' do
    it 'returns the environment' do
      include ApplicationHelper
      expect(env_str).to eq(Rails.env)
    end

    it 'returns empty for production' do
      include ApplicationHelper
      allow(Rails).to receive(:env).and_return('production')
      expect(env_str).to eq('')
    end
  end
end
