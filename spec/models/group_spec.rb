require 'rails_helper'

describe Group do
  attr_reader :collection
  attr_reader :group
  attr_reader :group_ldap

  before(:each) do
    @collection   = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    collection_id = mock_ldap_for_collection(collection)
    @group_ldap   = Group::LDAP.fetch(collection_id)
    @group        = Group.make_from_ldap(group_ldap)
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

  describe ':object_count' do
    attr_reader :objects

    before(:each) do
      @objects = Array.new(3) { |i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}") }
      collection.inv_objects << objects
    end

    it 'counts objects' do
      expect(group.object_count).to eq(objects.count)
    end
  end

  describe ':version_count' do
    attr_reader :objects

    before(:each) do
      @objects = Array.new(3) { |i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}") }
      collection.inv_objects << objects
      objects.each do |obj|
        create(:inv_version, inv_object: obj, number: 2)
        obj.version_number = 2
        obj.save!
      end
    end

    it 'counts versions' do
      expect(group.version_count).to eq(2 * objects.count)
    end
  end

  describe ':file_count' do
    attr_reader :objects

    before(:each) do
      @objects = Array.new(3) { |i| create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}") }
      collection.inv_objects << objects
      objects.each_with_index do |obj, i|
        v2 = create(:inv_version, inv_object: obj, number: 2)
        create(
          :inv_file,
          inv_object:  obj,
          inv_version: v2,
          pathname:    "producer/file-#{i}.bin",
          source:      'producer',
          role:        'data'
        )
        obj.version_number = 2
        obj.save!
      end
    end

    it 'counts files' do
      expect(group.file_count).to eq(objects.count)
    end
  end
end
