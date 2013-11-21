require 'test_helper'

class CollectionControllerTest < ActionController::TestCase
  test "view collection" do
    get(:index, {:group => "demo_merritt"}, {:uid => "anonymous"})
    assert_response(:success)
  end

  test "unauthorized collection access" do
    get(:index, {:group => "cdl_escholarship"}, {:uid => "anonymous"})
    assert_response(401)
  end

  test "nonexistent collection" do
    get(:index, {:group => "FOOBAR"}, {:uid => "anonymous"})
    assert_response(404)
  end

  test "search collection" do
    get(:search_results, {:group => "demo_merritt", :terms=>"test"}, {:uid => "anonymous"})
  end
end
