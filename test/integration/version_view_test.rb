require 'test_helper'

class VersionViewTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
  end

  test "download version works" do
    click_button("Guest")
    click_link("Demo Merritt")
    click_link("ark:/99999/fk40k2sqf")
    click_link("Version 1")
    click_button("Download version")

    # should be sent to dua page
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    check("accept")
    click_button("Accept")
    assert_equal(200, page.status_code)
    assert_equal("attachment; filename=ark+=99999=fk40k2sqf_version_1.zip", page.response_headers["Content-Disposition"])
  end
end
