require 'spec_helper'

feature 'object' do

  background do
    logs_in_with_my_credentials
  end

  
  scenario "object TEST TO BE COMPLETED" , :js => true do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click # goes to collection landing page
    expect(page).to have_content('Demo Merritt')
    FactoryGirl.create(:inv_object)
    FactoryGirl.create(:inv_version)
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
  end


end


