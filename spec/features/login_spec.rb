require 'features_helper'

describe 'login' do
  before(:each) do
    visit login_path
  end

  it 'accepts valid credentials' do
    fill_in "login", :with => "testuser01"
    fill_in "password", :with => "testuser01"
    click_button "Login"
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
  end

  it 'rejects invalid credentials' do
    fill_in "login", :with => "I am not testuser01"
    fill_in "password", :with => "I am not testuser01"
    click_button "Login"
    expect(page).to have_content('Login unsuccessful')
  end

end
