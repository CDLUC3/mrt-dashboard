require 'spec_helper'

feature 'user logs in' do

  scenario "with valid credentials " do #, :js => true do
    logs_in_with_my_credentials
    expect(page).to have_content('Welcome')
  end

  scenario "not with INVALID credentials " do #, :js => true do
    logs_in_with("","")
    expect(page).to have_content('Login unsuccessful')
  end


end

