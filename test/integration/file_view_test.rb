require 'test_helper'

class FileViewTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
    click_button("Guest")
    click_link("Demo Merritt")
  end

  test "view object works" do
    click_link("ark:/99999/fk40k2sqf")
    click_link("Version 1")
    click_link("mrt-erc.txt")

    # should be sent to dua page
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    check("accept")
    click_button("Accept")
    assert_equal(200, page.status_code)
    assert_equal("inline; filename=\"mrt-erc.txt\"", page.response_headers["Content-Disposition"])
  end

  test "download file redirect to latest version works" do
    visit("/d/ark%3A%2F99999%2Ffk40k2sqf/0/system%2Fmrt-erc.txt")
    # should be sent to dua page
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    check("accept")
    click_button("Accept")
    assert_equal(200, page.status_code)
    assert_equal("inline; filename=\"mrt-erc.txt\"", page.response_headers["Content-Disposition"])
  end

  test "cancel dua works" do
    click_link("ark:/99999/fk40k2sqf")
    click_link("Version 1")
    click_link("mrt-erc.txt")

    # should be sent to dua page
    click_button("Do Not Accept")
    assert_equal(200, page.status_code)
    assert_equal(current_path, "/m/ark%3A%2F99999%2Ffk40k2sqf/1")
  end
end
