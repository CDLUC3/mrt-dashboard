require 'test_helper'

class LargeObjectStorageTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
  end

  def fill_out_dua
    fill_in('Name', :with => 'Jane Doe')
    fill_in('Affiliation', :with => 'Doe International')
    fill_in('Email', :with => 'doe@mailinator.com')
    check("accept")
    click_button("Accept")
  end
  
  test "large object download works" do 
    click_button("Guest")
    click_link("Demo Merritt")
    click_link("ark:/99999/fk41z6855")
    click_button("Download object")

    # should be sent to dua page
    fill_out_dua()

    # now at large object page
    fill_in("Email", :with => "doe@mailinator.com")
    click_button("Submit")
    assert_equal("/m/ark%3A%2F99999%2Ffk41z6855", current_path)
    
    visit("/d/ark%3A%2F99999%2Ffk41z6855")
    fill_out_dua()

    # now at large object page, see if we can cancel
    click_button("Cancel")
    assert_equal("/m/ark%3A%2F99999%2Ffk41z6855", current_path)
  end
end
