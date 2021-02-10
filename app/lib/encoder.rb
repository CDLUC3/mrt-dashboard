require 'erb'
module Encoder

  def self.urlencode(item)
    ERB::Util.url_encode(item)
  end

  def self.urlunencode(item)
    CGI.unescape(item)
  end
end
