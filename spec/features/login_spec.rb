require 'features_helper'

describe 'login' do
  attr_reader :user_id
  attr_reader :password

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    col1_id = mock_collection('Collection 1')
    mock_permissions(user_id, {col1_id => PERMISSIONS_ALL})

    visit login_path
  end

  it 'accepts valid credentials' do
    fill_in 'login', :with => user_id
    fill_in 'password', :with => password
    click_button 'Login'
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
  end

  it 'rejects invalid credentials' do
    fill_in 'login', :with => "I am not #{user_id}"
    fill_in 'password', :with => "I am not #{password}"
    click_button 'Login'
    expect(page).to have_content('Login unsuccessful')
  end

end
