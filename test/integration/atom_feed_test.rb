require 'test_helper'

class AtomFeedTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections

  test "atom feed works" do
    get(:recent, :format=> "atom", :collection => "ark:/99999/fk4q24532")
    assert_response(:success)
    assert_select("title", "Recent objects")
    assert_select("entry") do |entries|
      assert_select(entries[0], "link") do |link|
        # wish there was a better way!
        get(link.to_s.match(/href="([^"]+)"/)[1])
      end
    end
  end
end
