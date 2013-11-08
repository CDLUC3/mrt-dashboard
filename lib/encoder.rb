module Encoder
  def urlencode_mod(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end 
