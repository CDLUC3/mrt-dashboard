module Encoder
  def urlencode(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def urlunencode(item)
    URI.unescape(item)
  end
end 
