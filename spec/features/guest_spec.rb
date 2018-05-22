require 'features_helper'

describe 'guest' do
  before :each do
    perms_by_group_id = (0..3).map do |i|
      [mock_collection("Collection #{i}"), PERMISSIONS_READ_ONLY]
    end.to_h
    mock_permissions(GUEST_USER_ID, perms_by_group_id)

    visit login_path
    click_button 'Guest'
  end

  it 'allows guest login' do
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
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
