require 'erb'
module Encoder

  def self.urlencode(item)
    ERB::Util.url_encode(item)
  end

  def self.urlunencode(item)
    URI.unescape(item)
  end
end
