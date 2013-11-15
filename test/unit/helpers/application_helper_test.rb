require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "dc_nice" do
    assert_equal(dc_nice([]), "[this space intentionally left blank]")
    assert_equal(dc_nice(nil), "[this space intentionally left blank]")
    assert_equal(dc_nice(["hello", "world"]), "hello; world")
  end
end
