require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
  test "can show dashboard" do
    get :show
    assert_response :success
  end
end
