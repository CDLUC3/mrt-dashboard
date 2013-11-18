require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "dc_nice" do
    assert_equal("", dc_nice([]))
    assert_equal("", dc_nice(nil))
    assert_equal("hello; world", dc_nice(["hello", "world"]))
  end
end
