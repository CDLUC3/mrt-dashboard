require 'features_helper'

describe 'login' do
  attr_reader :user_id
  attr_reader :password

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    col_id = mock_collection(name: 'Collection 1')
    mock_permissions(user_id, {col_id => PERMISSIONS_ALL})
  end

  it 'accepts valid credentials' do
    log_in_with(user_id, password)
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
  end

  it 'rejects invalid credentials' do
    log_in_with("not #{user_id}", "not #{password}")
    expect(page).to have_content('Login unsuccessful')
  end

end
