require 'test_helper'

class DuaTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
  end

  test "dua works after I forget to check accept" do
    click_button("Guest")
    click_link("Demo Merritt")
    click_link("ark:/99999/fk40k2sqf")
    click_button("Download object")

    # should be sent to dua page
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    click_button("Accept")
    
    # whoops, forget to check accept!
    check("accept")
    click_button("Accept")
    assert_equal(200, page.status_code)
    assert_equal("attachment; filename=\"ark+=99999=fk40k2sqf_object.zip\"", page.response_headers["Content-Disposition"])
  end
end
