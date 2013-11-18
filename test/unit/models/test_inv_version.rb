require 'test_helper'
 
class InvVersionTest < ActiveSupport::TestCase
  setup do
    @version = InvVersion.where(:ark => "ark:/99999/fk40k2sqf").first
  end

  test "who values" do
    assert_equal(["Dorothea Lange"], @version.dk_who)
  end

  test "what values" do
    assert_equal(["Fairs and Markets"], @version.dk_what)
  end

  test "when values" do
    assert_equal(["ca. 1954"], @version.dk_when)
  end

  test "where values" do
    assert_equal(["ark:/99999/fk40k2sqf", "ark:/13030/ft4b69n700"].sort, @version.dk_where.sort)
  end

  test "do not return (:unas) values" do
    version = InvVersion.where(:ark => "ark:/99999/unas").first
    assert_equal([], version.dk_where)
  end
end
