module Encoder

  def self.urlencode(item)
    # was URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    res = ''
    item.split.each do |c|
      res += '%20' if res != ''
      res += URI.encode_www_form_component(c)
    end
    res
  end

  def self.urlunencode(item)
    URI.decode_www_form_component(item)
  end
end
