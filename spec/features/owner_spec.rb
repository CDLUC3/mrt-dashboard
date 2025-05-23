require 'features_helper'

describe 'owners' do
  attr_reader :user_id
  attr_reader :password

  attr_reader :collection
  attr_reader :collection_id

  attr_reader :owner

  attr_reader :index_path

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    @owner = create(:inv_owner, name: 'Owner', ark: 'ark/owner')

    @collection = create(:private_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_id = mock_ldap_for_collection(collection)

    @choose_path = url_for(controller: :home, action: :choose_collection, only_path: true)
    @index_path = url_for(controller: :owner, action: :search_results, terms: '', owner: @owner.name, only_path: true)
  end

  after(:each) do
    @owner.delete
    log_out!
  end

  def mock_owner_name(_user, name)
    allow_any_instance_of(ApplicationController).to receive(:current_owner_name).and_return(name)
    allow_any_instance_of(ApplicationController).to receive(:available_groups).and_return([])
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
          erc_when: "2018-01-0#{i}",
          inv_owner_id: @owner.id
        )
      end
      collection.inv_objects << inv_objects
    end

    describe 'happy path', js: true do
      before(:each) do
        mock_owner_name(user_id, @owner.name)
        mock_permissions_all(user_id, collection_id)
        log_in_with(user_id, password)
        visit(@choose_path)
        expect(page).to have_content('The collections you have access to are listed below.')
      end

      it 'should display the owner name' do
        expect(page).to have_content("#{owner.name} Lookup")
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

        it 'finds by substring, no objects found' do
          fill_in('terms', with: 'Jan')
          click_button 'Go'
          expect(page).to have_content('There were no items that had the text matching')
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

        it 'finds by arks' do
          expected_objects = [1, 3, 5].map { |i| inv_objects[i] }
          arks = expected_objects.map(&:ark)
          fill_in('terms', with: arks.join(' '))
          click_button 'Go'

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

      end
    end

    it 'requires a user' do
      visit(index_path)
      expect(page).to have_content('Not authorized')
    end

    it 'requires read permissions', js: true do
      log_in_with(user_id, password)
      visit(index_path)
      visit(index_path) if current_url =~ /choose_collection$/
      expect(page).to have_content('Not authorized')
    end

    it 'requires user to be bound to a global owner', js: true do
      mock_permissions_all(user_id, collection_id)
      log_in_with(user_id, password)
      visit(index_path)
      expect(page).to have_content('Not authorized')
    end

  end

end
