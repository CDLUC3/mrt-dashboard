require 'features_helper'

describe 'collections' do
  attr_reader :user_id
  attr_reader :password

  attr_reader :collection
  attr_reader :collection_id

  attr_reader :index_path

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)

    @index_path = url_for(controller: :collection, action: :index, group: collection_id, only_path: true)
  end

  after(:each) do
    log_out!
  end

  it 'should display the collection name' do
    mock_permissions_all(user_id, collection_id)
    log_in_with(user_id, password)
    expect(page).to have_content("Collection: #{collection.name}")
  end

  describe 'index' do
    attr_reader :inv_objects

    before(:each) do
      @inv_objects = Array.new(6) do |i|
        create(
          :inv_object,
          erc_who: 'Doe, Jane',
          erc_what: "Object #{i}",
          erc_when: "2018-01-0#{i}"
        )
      end
      collection.inv_objects << inv_objects
    end

    describe 'happy path' do
      before(:each) do
        mock_permissions_all(user_id, collection_id)
        log_in_with(user_id, password)
      end

      it 'should list the objects' do
        inv_objects.each do |obj|
          expect(page).to have_content(obj.ark)
          expect(page).to have_content(obj.erc_who)
          expect(page).to have_content(obj.erc_what)
          expect(page).to have_content(obj.erc_when)
        end
      end

      it 'should let the user navigate to an object' do
        obj = inv_objects[0]
        click_link(obj.ark)
        expect(page).to have_content("Object: #{obj.ark}")
      end

      it 'should display an "Add Object" link' do
        add_obj_link = find_link('Add object')
        expect(add_obj_link).not_to be_nil
        add_obj_link.click
        expect(page.title).to include('Add Object')
      end

      describe 'search' do
        it 'finds by author keywords' do
          fill_in('terms', with: 'Jane')
          click_button 'Go'
          inv_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            # who is the same for all test objects so don't bother
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end
        end

        it 'finds by substring' do
          fill_in('terms', with: 'Jan')
          click_button 'Go'
          inv_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            # who is the same for all test objects so don't bother
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end
        end

        it 'finds by arks' do
          expected_objects = [1, 3, 5].map {|i| inv_objects[i]}
          arks = expected_objects.map(&:ark)
          fill_in('terms', with: arks.join(' '))
          click_button 'Go'

          expected_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            # who is the same for all test objects so don't bother
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end

          (inv_objects - expected_objects).each do |obj|
            expect(page).not_to have_content(obj.ark)
            # who is the same for all test objects so don't bother
            expect(page).not_to have_content(obj.erc_what)
            expect(page).not_to have_content(obj.erc_when)
          end
        end
      end
    end

    it 'requires a user' do
      visit(index_path)
      expect(page).to have_content('Not authorized')
    end

    it 'requires read permissions' do
      log_in_with(user_id, password)
      visit(index_path)
      expect(page).to have_content('Not authorized')
    end

    it 'requires a valid group' do
      mock_permissions_all(user_id, collection_id)
      allow(Group).to receive(:find).with(collection_id).and_raise(LdapMixin::LdapException)
      log_in_with(user_id, password)
      visit(index_path)
      expect(page).to have_content("doesn't exist")
    end

  end
end
