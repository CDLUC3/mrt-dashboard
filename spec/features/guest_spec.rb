require 'spec_helper'

feature 'guest' do

  scenario "A guest should be able to login as a guest" do
    visit login_path
    click_button "Guest"
    expect(page).to have_content('Welcome')
  end

  scenario "A guest should be able to click on a collection" do #, :js => true do
    visit login_path
    click_button "Guest"
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to have_content('Collection home')
    end
  end

  scenario "A guest should NOT be able to add an object" do#, :js => true do
    visit login_path
    click_button "Guest"
    find(:xpath, "//table/tbody/tr[1]/td[1]/a[1]").click
    within("#menu-1") do
      expect(page).to_not have_content('Add object')
    end
  end

end

#title choose collection: UC3 Merritt: Choose Collection: development

# page.title
# page.has_title? "my title"
# page.has_no_title? "my not found title"
# So you can test the title like:

# expect(page).to have_title "my_title"
# According to github.com/jnicklas/capybara/issues/863 the following is also working with capybara 2.0:

# expect(first('title').native.text).to eq "my title"

