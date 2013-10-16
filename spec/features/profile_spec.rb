require 'spec_helper'

feature 'profile' do

  background do
    logs_in_with_my_credentials
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click #collection landing page
  end

  scenario "link should be visible" do #, :js => true do
    expect(page).to have_content('Profile')
  end

  scenario "profile page should be available" do # , :js => true do
    click_link('Profile')
    expect(page).to have_title('Update Profile')
  end

  scenario "updating telephone number" do #, :js => true do
    click_link('Profile')
    fill_in "telephonenumber", :with => "000000000"
    click_button "Save changes"
    expect(page).to have_content('Your profile has been updated.')
    find_field('telephonenumber').value.should eq '000000000'
  end

  scenario "updating timezone" do #, :js => true do
    click_link('Profile')
    select 'Europe/Helsinki', :from => "tzregion"
    click_button "Save changes"
    expect(page).to have_content('Your profile has been updated.')
    find("#tzregion option[value='Europe/Helsinki']").should be_selected
    select 'Europe/Malta', :from => "tzregion"
    click_button "Save changes"
    expect(page).to have_content('Your profile has been updated.')
    find("#tzregion option[value='Europe/Malta']").should be_selected
  end

end

