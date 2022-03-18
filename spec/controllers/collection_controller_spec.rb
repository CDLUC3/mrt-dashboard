require 'rails_helper'
require 'support/presigned'

RSpec.describe CollectionController, type: :controller do

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
      @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

      @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1', ark: 'ark:/collection_1')
      @collection_id = mock_ldap_for_collection(collection)
      @objects = []
      (0..2).each do |i|
        @objects.append(
          create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object #{i}", erc_when: "2018-01-0#{i}")
        )
        sleep 1
      end
      collection.inv_objects << objects

      @object_ark = objects[0].ark
      @object = objects[0]
      lid = InvLocalid.new(
        local_id: 'my-local-id',
        inv_object: @object,
        inv_owner: @object.inv_owner,
        created: Time.now
      )
      lid.save!

      @client = mock_httpclient
    end

    describe ':index' do
      it 'prevents index view without read permission' do
        request.session.merge!({ uid: user_id })
        get(:index, params: { group: @collection.group })
        expect(response.status).to eq(401)
      end

      it 'prevents localid search without read permission' do
        request.session.merge!({ uid: user_id })
        get(:local_id_search, params: { group: @collection.group, terms: 'my-local-id' })
        expect(response.status).to eq(401)
      end

      it 'allow index view' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })
        get(:index, params: { group: @collection.group })
        expect(response.status).to eq(200)
      end

      it 'localid search no results' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })
        get(:local_id_search, params: { group: @collection.group, terms: 'my-local-id-not-found' })
        expect(response.status).to eq(201)
      end

      it 'localid search - result found' do
        mock_permissions_all(user_id, collection_id)
        request.session.merge!({ uid: user_id })
        get(:local_id_search, params: { group: @collection.group, terms: 'my-local-id' })
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to match(".*/api/object_info/#{CGI.escape(@object.ark)}")
      end
    end

  end
end
