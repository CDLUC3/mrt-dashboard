require 'test_helper'

class LargeObjectStorageTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
  end

  test "large object download works" do 
    click_button("Guest")
    click_link("Demo Merritt")
    click_link("ark:/99999/fk41z6855")
    click_button("Download object")

    # should be sent to dua page
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    check("accept")
    click_button("Accept")

    # now at large object page
    fill_in("Email", :with => "doe@mailinator")
    click_button("Submit")
  end
end
