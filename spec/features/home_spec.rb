require 'features_helper'

describe 'home' do

  before(:each) do
    visit('/')
  end

  it 'is a Merritt page' do
    expect(page).to have_content('Merritt')
  end

  it 'has a login link' do
    click_link('Login', match: :first)
    expect(page).to have_content('Merritt')
  end

  describe 'choose a collection', js: true do
    attr_reader :user_id
    attr_reader :password
    attr_reader :col_ids

    before(:each) do
      @password = 'correcthorsebatterystaple'
      @user_id = mock_user(name: 'Jane Doe', password: password)

      col1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
      col2 = create(:inv_collection, name: 'Collection 2', mnemonic: 'collection_2')

      @col_ids = [col1, col2].map { |c| mock_ldap_for_collection(c) }
    end

    after(:each) do
      log_out!
    end

    it 'allows user to click on a collection' do
      mock_permissions_all(user_id, col_ids)
      log_in_with(user_id, password)

      click_link('Collection 1', match: :first)
      expect(page).to have_content('Collection home')
    end

    it "should redirect to the collection page if there's only one" do
      mock_permissions_all(user_id, col_ids[0])
      log_in_with(user_id, password)
      expect(page).to have_content('Collection home')
    end

  end

  describe 'audit_replic_stats' do
    it 'html version' do
      visit '/state.html'
      find('table.state')
      within('table.state') do
        expect(page).to have_selector('thead tr', count: 1)
        expect(page).to have_selector('tbody tr', count: 4)
      end
    end

    it 'json version' do
      visit '/state.json'
    end
  end

end
