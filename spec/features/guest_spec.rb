require 'spec_helper'

describe 'guest' do

  before :each do
    visit login_path
    click_button "Guest"
  end

  it "should be able to login as a guest" do
    expect(page).to have_content('Welcome')
  end

  it "should be able to click on a collection" do #, :js => true do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to have_content('Collection home')
    end
  end

  it "should NOT be able to add an object" do#, :js => true do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to_not have_content('Add object')
    end
  end

end

