require 'spec_helper'

feature 'homepage' do

  background do
    visit root_path
  end

  scenario "Merritt Homepage is working" do
    expect(page).to have_content('Merritt')
  end

  scenario "A user should be able to access the Login page from the Homepage" do
    click_link "Login"
    expect(page).to have_content('Merritt')
  end

end

#title home:  UC3 Merritt Home: development
#title login:  UC3 Merritt Login: development