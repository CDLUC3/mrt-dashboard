require 'rails_helper'

describe Group do
  attr_reader :collection
  attr_reader :group
  attr_reader :group_ldap

  before(:each) do
    @collection = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    collection_id = mock_ldap_for_collection(collection)
    @group_ldap = Group::LDAP.fetch(collection_id)
    @group = Group.make_from_ldap(group_ldap)
  end

  describe ':find_all' do
    it 'delegates to Group::LDAP' do
      result = ['I am the test result']
      expect(Group::LDAP).to receive(:find_all).and_return(result)
      expect(Group.find_all).to eq(result)
    end
  end

  describe ':find_users' do
    it 'delegates to Group::LDAP' do
      grp_id = 'I am the group ID'
      result = ['I am the test result']
      expect(Group::LDAP).to receive(:find_users).with(grp_id).and_return(result)
      expect(Group.find_users(grp_id)).to eq(result)
    end
  end

  describe ':sparql_id' do
    it 'wraps the ARK' do
      expected_url = "http://ark.cdlib.org/#{collection.ark}"
      expect(group.sparql_id).to eq(expected_url)
    end
  end
end
