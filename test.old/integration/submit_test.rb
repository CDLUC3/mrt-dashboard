require 'test_helper'

class LargeObjectStorageTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections, :inv_files

  setup do
    visit(logout_path)
    visit(login_path)
  end

  test "upload version via UI" do
    fill_in("login", :with=>"merritt-test")
    fill_in("password", :with=>"test")
    click_button("Login")
    click_link("Add object")
    attach_file("file", File.join(File.dirname(__FILE__), '..', 'fixtures', 'files', 'helloworld.txt'))
    fill_in("title", :with=>"Automated test")
    fill_in("author", :with=>"P. Dant")
    fill_in("date", :with=>Time.now.to_s)
    fill_in("local_id", :with=>"foobar")
    click_button("Submit")
    assert(has_content?("Submission Received"))
  end
end
