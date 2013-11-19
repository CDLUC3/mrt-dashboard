require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  setup do
    visit(logout_path)
    visit(login_path)
  end

  test "guest login works" do
    click_button "Guest"
  end
  
  test "login works" do
    fill_in("login", :with=>"merritt-test")
    fill_in("password", :with=>"test")
    click_button("Login")
  end

  test "user with single collection is redirected" do
    fill_in("login", :with=>"merritt-test")
    fill_in("password", :with=>"test")
    click_button("Login")
    assert_equal("/m/opencontext", current_path)
  end
end
