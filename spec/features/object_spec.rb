require 'spec_helper'

feature 'object' do

  background do
    logs_in_with_my_credentials
  end

  
  scenario "object TEST TO BE COMPLETED" , :js => true do
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click # goes to collection landing page
    expect(page).to have_content('Demo Merritt')
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
   # FactoryGirl.create(:inv_object).should be_valid
  end


end


# Capybara.default_wait_time = 20

# /object?group=demo_merritt&amp;object=ark%3A%2F90135%2Fq15h7d7h

# first(:link, "Agree").click
# find(:xpath, "//tr[contains(.,'Foo')]/td/a", :text => 'manage').click

# http://merritt-dev.cdlib.org/m/demo_merritt

# visit "/sessions/new"

# it should be "//a[@href = 'google.com']"

# /m/:group(.:format)                    collection#index
#/m/:group/:version(.:format)           version#index
 #                   /d/:object(.:format)                   object#download
 #                   /d/:object/:version(.:format)          version#download
 #                   /d/:object/:version/:file(.:format)    file#display {:file=>/.+/i}