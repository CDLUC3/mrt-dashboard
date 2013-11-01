require 'test_helper'

class GuestLoginTest < ActionDispatch::IntegrationTest
  test "guest login works" do
    visit login_path
    click_button "Guest"
  end
  
  test "login works" do
    visit(login_path)
    fill_in("login", :with=>"merritt-test")
    fill_in("password", :with=>"test")
    click_button("Login")
  end

  test "user with single collection is redirected" do
    visit(login_path)
    fill_in("login", :with=>"merritt-test")
    fill_in("password", :with=>"test")
    click_button("Login")
    assert_equal(current_path, "/m/opencontext")
  end
end
