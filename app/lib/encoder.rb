module Encoder

  def self.urlencode(item)
    # was URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    URI.encode_www_form_component(item)
  end

  def self.urlunencode(item)
    URI.decode_www_form_component(item)
  end
end
