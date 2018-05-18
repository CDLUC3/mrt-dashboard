require 'features_helper'

describe 'home' do

  before(:each) do
    visit('/')
  end

  it 'is a Merritt page' do
    expect(page).to have_content('Merritt')
  end

  it 'has a login link' do
    click_link "Login"
    expect(page).to have_content('Merritt')
  end

end

