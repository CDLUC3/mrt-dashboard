require 'rspec/expectations'
require 'time'

RSpec::Matchers.define :be_time do |expected|

  def same_offset(actual, expected)
    expected.utc_offset == actual.utc_offset
  end

  def within(expected, actual, delta)
    ((expected.to_r - actual.to_r).abs < delta)
  end

  match do |actual|
    return actual.nil? unless expected
    raise "Expected value #{expected} is not a Time" unless expected.is_a?(Time)
    same_offset(actual, expected) && within(expected, actual, 0.5)
  end

  failure_message do |actual|
    expected_str = expected ? expected.iso8601 : 'nil'
    actual_str = actual ? actual.iso8601 : 'nil'
    "expected time:\n#{expected_str}\n\nbut was:\n#{actual_str}"
  end

end
