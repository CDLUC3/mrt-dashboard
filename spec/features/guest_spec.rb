require 'features_helper'

describe 'guest' do
  attr_reader :collections
  before :each do
    @collections = Array.new(3) do |i|
      db_collection = create(:inv_collection, name: "Collection #{i}", mnemonic: "collection_#{i}")
      mock_ldap_for_collection(db_collection)
      db_collection
    end
    mock_permissions_read_only(GUEST_USER_ID, collections.map(&:mnemonic))

    visit login_path
    click_button 'Guest'
  end

  it 'allows guest login' do
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
  end

  it 'should not have a profile link' do
    expect(page).not_to have_content('Profile')
  end

  it 'should have a link for each available colleciton', js: true do
    collections.each do |collection|
      collection_link = find_link(collection.name)
      expect(collection_link).not_to be_nil
    end
  end

  it 'allows guest user to click on a collection', js: true do
    collection = collections[0]
    collection_link = find_link(collection.name)
    collection_link.click
    expect(page.title).to include(collection.name)
  end

  it 'should respect read-only permissions', js: true do
    find_link(collections[0].name).click
    expect(page).to_not have_content('Add object')
  end
end
