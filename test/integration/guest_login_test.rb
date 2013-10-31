require 'test_helper'

class GuestLoginTest < ActionDispatch::IntegrationTest
  test "guest login works" do
    visit login_path
    click_button "Guest"
  end
end
