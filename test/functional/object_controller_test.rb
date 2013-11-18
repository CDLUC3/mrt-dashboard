require 'test_helper'

class ObjectControllerTest < ActionController::TestCase
  test "view object" do
    get(:index, {:object => "ark:/99999/fk40k2sqf"}, {:uid => "anonymous"})
    assert_response(:success)
  end

  test "prevent view object not allowed" do
    get(:index, {:object => "ark:/99999/fk40k2sqf"}, {:uid => "merritt-test"})
    assert_redirected_to(:controller=>:home, :action=>:index)
  end
end
