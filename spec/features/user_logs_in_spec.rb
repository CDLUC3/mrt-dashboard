require 'spec_helper'

feature 'user logs in' do

  scenario "with valid credentials " do #, :js => true do
    logs_in_with("","")
    expect(page).to have_content('Welcome')
  end

  scenario "with INVALID credentials " do #, :js => true do
    logs_in_with("","")
    expect(page).to have_content('Login unsuccessful')
  end


  def logs_in_with(email, password)
    visit login_path
    fill_in "login", :with => email
    fill_in "password", :with => password
    click_button "Login"
  end

end

