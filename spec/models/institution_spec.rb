require 'rails_helper'

describe Institution do
  describe ':find_all' do
    it 'delegates to Institution::LDAP' do
      result = ['I am the test result']
      expect(Institution::LDAP).to receive(:find_all).and_return(result)
      expect(Institution.find_all).to eq(result)
    end
  end
end
