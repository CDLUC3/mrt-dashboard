require 'erb'
module Encoder

  def self.urlencode(item)
    ERB::Util.url_encode(item)
  end

  def self.urlunencode(item)
    # Preserve the encoding of plus signs that may be part of a filename
    item = item.gsub('+', '%2B')
    CGI.unescape(item)
  end
end
