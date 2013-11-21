require 'test_helper'

class ObjectViewTest < ActionDispatch::IntegrationTest
  setup do
    Capybara.run_server = false
    Capybara.app_host = "http://merritt-stage.cdlib.org/"
    Capybara.default_driver = :selenium
    visit(logout_path)
    visit(login_path)
  end
  
  test "view object works" do
    click_button("Guest")
    click_link("Demo Merritt collection")
    click_link("ark:/99999/fk4r2356f")
    assert_equal(current_path, "/m/ark%3A%2F99999%2Ffk4r2356f")
  end
end
