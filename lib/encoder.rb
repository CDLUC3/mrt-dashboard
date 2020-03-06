# rubocop:disable Lint/UriEscapeUnescape
module Encoder

  def self.urlencode(item)
    URI.escape(item, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def self.urlunencode(item)
    URI.unescape(item)
  end
end
# rubocop:enable Lint/UriEscapeUnescape
