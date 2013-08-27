require 'spec_helper'

feature 'homepage' do

  it "should have Merritt Homepage" do
    visit root_path
    expect(page).to have_content('Merritt')
  end

  it "should be able to access the Login page" do
    visit root_path
    click_link "Login"
    expect(page).to have_content('Login')
  end

end