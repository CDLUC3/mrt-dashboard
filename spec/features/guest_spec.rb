require 'features_helper'

describe 'guest' do
  before :each do
    mock_permissions_read_only(GUEST_USER_ID, (0..3).map do |i|
      mock_collection(name: "Collection #{i}")
    end)

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

  it 'allows guest user to click on a collection' do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to have_content('Collection home')
    end
  end

  it 'should respect read-only permissions' do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to_not have_content('Add object')
    end
  end
end
