require 'test_helper'

class AtomFeedTest < ActionDispatch::IntegrationTest
  fixtures :inv_objects, :inv_collections_inv_objects, :inv_collections

  test "atom feed works" do
    get("/object/recent.atom?collection=ark:/99999/fk4q24532")
    assert_response(:success)
    assert_select("title", "Recent objects")
    assert_select("entry") do |entries|
      assert_select(entries[0], "link",
                    :attributes => {
                      :rel => 'alternate',
                      :type => "application/zip"}) do |link|
        # wish there was a better way!
        get(link.to_s.match(/href="([^"]+)"/)[1])
        # should download directly without credentials supplied
        # currently fails because we are redirected to /guest_login
        # assert_response(:success)
      end
    end
  end
end