require 'rails_helper'
require 'support/presigned'

RSpec.describe OwnerController, type: :controller do

  attr_reader :user_id

  attr_reader :collection
  attr_reader :collection_id
  attr_reader :objects

  attr_reader :object
  attr_reader :object_ark

  attr_reader :file
  attr_reader :client

  describe 'default filenames' do
    before(:each) do
      @testlocalid = 'my-local-id'
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

      @owner = create(:inv_owner, name: 'Owner', ark: 'ark/owner')

      @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1', ark: 'ark:/collection_1')
      @collection_id = mock_ldap_for_collection(collection)
      @objects = []
      3.times do |i|
        @objects.append(
          create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}", inv_owner_id: @owner.id)
        )
        sleep 1
      end
      collection.inv_objects << objects

      @object_ark = objects[0].ark
      @object = objects[0]
      lid = InvLocalid.new(
        local_id: @testlocalid,
        inv_object: @object,
        inv_owner: @object.inv_owner,
        created: Time.now
      )
      lid.save!

      @client = mock_httpclient
    end

    def mock_owner_name(name)
      allow_any_instance_of(ApplicationController).to receive(:current_owner_name).and_return(name)
    end

    describe ':index' do

      it 'prevents localid search without read permission' do
        request.session.merge!({ uid: user_id })
        get(:search_results, params: { terms: 'my-local-id', owner: @owner.name })
        expect(response.status).to eq(401)
      end

      it 'localid search no results' do
        mock_permissions_all(user_id, collection_id)
        mock_owner_name(@owner.name)
        request.session.merge!({ uid: user_id })
        get(:search_results, params: { terms: 'my-local-id-not-found', owner: @owner.name })
        expect(response.status).to eq(201)
      end

      it 'empty terms search no results' do
        mock_permissions_all(user_id, collection_id)
        mock_owner_name(@owner.name)
        request.session.merge!({ uid: user_id })
        get(:search_results, params: { terms: '', owner: @owner.name })
        expect(response.status).to eq(201)
      end

      it 'localid search - result found' do
        mock_permissions_all(user_id, collection_id)
        mock_owner_name(@owner.name)
        request.session.merge!({ uid: user_id })
        get(:search_results, params: { terms: @testlocalid, owner: @owner.name })
        expect(response.status).to eq(200)
      end
    end

  end
end
