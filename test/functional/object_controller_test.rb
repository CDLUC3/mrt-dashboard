require 'test_helper'

class ObjectControllerTest < ActionController::TestCase
  test "view object" do
    get(:index, {:object => "ark:/99999/fk40k2sqf"}, {:uid => "anonymous"})
    assert_response(:success)
  end
end
