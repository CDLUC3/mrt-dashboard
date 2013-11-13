require 'test_helper'

class CollectionControllerTest < ActionController::TestCase
  test "view collection" do
    get(:index, {:group => "demo_merritt"}, {:uid => "anonymous"})
    assert_response(:success)
  end

  test "unauthorized collection access" do
    assert_raises(ActiveResource::UnauthorizedAccess) do
      get(:index, {:group => "cdl_escholarship"}, {:uid => "anonymous"})
    end
  end

  test "nonexistent collection" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get(:index, {:group => "FOOBAR"}, {:uid => "anonymous"})
    end
  end

  test "search collection" do
    get(:search_results, {:group => "demo_merritt"}, {:uid => "anonymous"})
  end
end
