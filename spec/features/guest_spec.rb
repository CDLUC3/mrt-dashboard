require 'spec_helper'

feature 'guest' do

  scenario "should be able to login as a guest" do
    visit login_path
    click_button "Guest"
    expect(page).to have_content('Welcome')
  end

  scenario "should be able to click on a collection", :js => true do
    visit login_path
    click_button "Guest"
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to have_content('Collection home')
    end
  end

end

