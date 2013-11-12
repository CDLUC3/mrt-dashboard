module Encoder
  def urlencode(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end 
