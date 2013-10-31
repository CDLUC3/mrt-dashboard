require 'test_helper'

class ObjectViewTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections

  test "object view works" do
    visit(login_path)
    click_button("Guest")
    click_link("Demo Merritt")
    click_link("ark:/99999/fk4qv5n4z")
  end
end
