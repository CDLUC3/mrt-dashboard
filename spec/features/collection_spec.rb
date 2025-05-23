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

  describe 'index', js: true do
    attr_reader :inv_objects

    before(:each) do
      @inv_objects = Array.new(6) do |i|
        init = (65 + i).chr
        create(
          :inv_object,
          erc_who: "Doe, Jane #{init}.",
          erc_what: "Object #{i}",
          erc_when: "2018-01-0#{i}"
        )
      end
      collection.inv_objects << inv_objects
    end

    after(:each) do
      wait_for_ajax!
      expect(page).not_to have_content('calculating') # indicates ajax count failure
    end

    describe 'happy path', js: true do
      before(:each) do
        mock_permissions_all(user_id, collection_id)
        log_in_with(user_id, password)
      end

      it 'should display the collection name' do
        expect(page).to have_content("Collection: #{collection.name}")
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

      describe 'add_object', js: true do
        before(:each) do
          add_obj_link = find_link('Add object')
          expect(add_obj_link).not_to be_nil
          add_obj_link.click
        end

        it 'should display an "Add Object" link' do
          expect(page.title).to include('Add Object')
        end

        it 'Add object without attaching a file' do
          expect(page.title).to include('Add Object')
          find('input#title').set('sample file')
          find('input#author').set('sample author')
          find_button('Submit').click
          sleep 1
          expect(page.title).to include('Add Object')
          expect(find('p.error-message')).to have_content('You must choose a filename to submit.')
        end

      end

      describe 'search' do
        it 'finds by author keywords' do
          fill_in('terms', with: 'Jane')
          click_button 'Go'
          inv_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            expect(page).to have_content(obj.erc_who)
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end
        end

        it 'finds by substring, defaults to full listing' do
          fill_in('terms', with: 'Jan')
          click_button 'Go'
          inv_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            expect(page).to have_content(obj.erc_who)
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end
        end

        it 'finds by ark' do
          obj = inv_objects[0]
          ark = obj.ark
          fill_in('terms', with: ark)
          click_button 'Go'

          expect(page).to have_content(obj.ark)
          expect(page).to have_content(obj.erc_who)
          expect(page).to have_content(obj.erc_what)
          expect(page).to have_content(obj.erc_when)
        end

        # TODO: improve this test by having an actual filename to search
        it 'find - search without wildcard' do
          fill_in('terms', with: 'foozzz')
          click_button 'Go'

          expect(page).to have_content('There were no items that had the text matching')
        end

        # TODO: improve this test by having an actual filename to search
        it 'find - search with wildcard' do
          fill_in('terms', with: 'f*ozzz')
          click_button 'Go'

          expect(page).to have_content('There were no items that had the text matching')
        end

        it 'finds by arks' do
          expected_objects = [1, 3, 5].map { |i| inv_objects[i] }
          arks = expected_objects.map(&:ark)
          fill_in('terms', with: arks.join(' '))
          sleep 1

          click_button 'Go'
          sleep 1

          expected_objects.each do |obj|
            expect(page).to have_content(obj.ark)
            expect(page).to have_content(obj.erc_who)
            expect(page).to have_content(obj.erc_what)
            expect(page).to have_content(obj.erc_when)
          end

          (inv_objects - expected_objects).each do |obj|
            expect(page).not_to have_content(obj.ark)
            expect(page).not_to have_content(obj.erc_who)
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

    it 'guest login redirect' do
      log_in_with(LDAP_CONFIG['guest_user'], LDAP_CONFIG['guest_password'])
      allow(APP_CONFIG['redirects']).to receive(:fetch).with('collection_1_profile', '').and_return('https://cdlib.org/')
      visit(index_path)
      visit(index_path) if current_url =~ /choose_collection$/
      expect(current_url).to eq('https://cdlib.org/')
    end

    it 'requires read permissions', js: true do
      log_in_with(user_id, password)
      visit(index_path)
      visit(index_path) if current_url =~ /choose_collection$/
      expect(page).to have_content('Not authorized')
    end

    it 'requires a valid group', js: true do
      mock_permissions_all(user_id, collection_id)
      allow(Group).to receive(:find).with(collection_id).and_raise(LdapMixin::LdapException)
      log_in_with(user_id, password)
      visit(index_path)
      expect(page).to have_content("doesn't exist")
    end

  end

end
