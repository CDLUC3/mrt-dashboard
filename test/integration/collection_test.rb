require 'test_helper'

class CollectionTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections

  test "/m/ access to collection ark works without login" do
    visit(logout_path)
    visit("/m/ark%3A%2F99999%2Ffk4q24532")
    assert_equal(200, page.status_code)
  end
  
  test "/m/ access to collection name works without login" do
    visit(logout_path)
    visit("/m/demo_merritt")
    assert_equal(200, page.status_code)
  end
end
