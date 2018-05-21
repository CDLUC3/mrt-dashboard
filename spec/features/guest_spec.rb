require 'features_helper'

describe 'guest' do
  before :each do
    visit login_path
    click_button 'Guest'
  end

  it 'allows guest login' do
    expect(page).not_to have_content('Login unsuccessful')
    expect(page).to have_content('Logout')
  end
end
