require 'spec_helper'

feature 'homepage' do

  it "Merritt Homepage is working" do
    visit root_path
    expect(page).to have_content('Merritt')
  end

  it "A user should be able to access the Login page from the Homepage" do
    visit root_path
    click_link "Login"
    expect(page).to have_content('Merritt')
  end

end