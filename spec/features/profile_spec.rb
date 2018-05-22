require 'features_helper'

describe 'profile' do
  attr_reader :user_id
  attr_reader :tzregion
  attr_reader :telephonenumber

  before(:each) do
    password = 'correcthorsebatterystaple'
    @tzregion = 'Atlantic/Madeira'
    @telephonenumber = '+44 06 496 1632'
    @user_id = mock_user(
      name: 'Jane Doe',
      password: password,
      tzregion: @tzregion,
      telephonenumber: @telephonenumber
    )
    col_id = mock_collection(name: "Collection 1")
    mock_permissions(user_id, {col_id => PERMISSIONS_ALL})
    log_in_with(user_id, password)
  end

  it 'should have a profile link' do
    expect(page).to have_content('Profile')
  end

  describe 'profile link' do
    before(:each) do
      click_link('Profile')
    end

    it 'should display the profile' do
      expect(page).to have_title('Update Profile')

      expect(find_field('givenname').value).to eq('Jane')
      expect(find_field('sn').value).to eq('Doe')
      expect(find_field('mail').value).to eq("#{user_id}@example.edu")
      expect(find_field('tzregion').value).to eq(tzregion)
      expect(find_field('telephonenumber').value).to eq(telephonenumber)
    end

    it 'should allow the user to change their telephone number' do
      new_number = "+1 999-958-5555"

      click_link('Profile')
      fill_in "telephonenumber", :with => new_number

      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'telephonenumber', new_number)
      click_button "Save changes"
      expect(page).to have_content('Your profile has been updated.')
    end

    it 'should allow the user to change their time zone' do
      click_link('Profile')
      select 'Europe/Helsinki', :from => "tzregion"

      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'tzregion', 'Europe/Helsinki')
      click_button "Save changes"
      expect(page).to have_content('Your profile has been updated.')
    end
  end

end
