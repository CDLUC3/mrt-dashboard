require 'features_helper'

describe 'profile', js: true do
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
    col_id = mock_collection(name: 'Collection 1')
    mock_permissions(user_id, { col_id => PERMISSIONS_ALL })
    log_in_with(user_id, password)
  end

  after(:each) do
    log_out!
  end

  it 'should have a profile link' do
    find('#user-dropdown').hover
    expect(page).to have_content('Profile')
  end

  describe 'profile link' do
    before(:each) do
      find('#user-dropdown').hover
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
      new_number = '+1 999-958-5555'

      fill_in('telephonenumber', with: new_number)

      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'telephonenumber', new_number)
      click_button 'Save changes'
      expect(page).to have_content(UserController::PROFILE_UPDATED_MSG)
    end

    it 'should allow the user to delete their telephone number' do
      new_number = ''

      fill_in('telephonenumber', with: new_number)

      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'telephonenumber', new_number)
      click_button 'Save changes'
      expect(page).to have_content(UserController::PROFILE_UPDATED_MSG)
    end

    it 'should allow the user to change their time zone' do
      select('Europe/Helsinki', from: 'tzregion')

      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'tzregion', 'Europe/Helsinki')
      click_button 'Save changes'
      expect(page).to have_content(UserController::PROFILE_UPDATED_MSG)
    end

    it 'should not allow the user to clear required fields' do
      UserController::REQUIRED.keys.each { |field| fill_in(field, with: '') }
      expect(User::LDAP).not_to receive(:replace_attribute)
      click_button 'Save changes'
      expect(page).to have_content(UserController::REQUIRED.values.join(', '))
      expect(page).not_to have_content(UserController::PROFILE_UPDATED_MSG)
    end

    it 'should allow the user to change their password' do
      new_password = 'elvis'
      fill_in('userpassword', with: new_password)
      fill_in('repeatuserpassword', with: new_password)
      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).to receive(:replace_attribute).with(user_id, 'userpassword', new_password)
      click_button 'Save changes'
      expect(page).to have_content(UserController::PROFILE_UPDATED_MSG)
    end

    it 'should require passwords to match' do
      fill_in('userpassword', with: 'elvis')
      fill_in('repeatuserpassword', with: 'not elvis')
      allow(User::LDAP).to receive(:replace_attribute).with(user_id, any_args).and_return(true)
      expect(User::LDAP).not_to receive(:replace_attribute).with(user_id, 'userpassword', anything)
      click_button 'Save changes'
      expect(page).to have_content(UserController::PASSWORD_MISMATCH_MSG)
      expect(page).not_to have_content(UserController::PROFILE_UPDATED_MSG)
    end
  end

end
