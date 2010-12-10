class Pairtree

  def self.encode(id)
    #first pass
    encode_regex = /[\"*+,<=>?\\^|]|[^\x21-\x7e]/u
    first_pass_id = id.gsub(encode_regex) { |m| "^%02x"%m.ord }

    # second pass
    char_encode_conv = {'/'=>'=',':'=>'+','.'=>','}
    second_pass_id = first_pass_id.split(//).collect { |char|
char_encode_conv[char] || char}.join
  end

  def self.decode(id)
    # first pass (reverse second from encode)
    char_decode_conv = {'='=>'/','+'=>':',','=>'.'}
    first_pass_id = id.split(//).collect { |char| char_decode_conv[char] ||
char}.join

    # second pass (reverse first from encode)
    decode_regex = /\^(..)/u
    second_pass_id = first_pass_id.gsub(decode_regex) { $1.hex.chr }
  end

  def self.to_ppath(id, shorty=2)
    self.split_string_to_dpath(self.encode(id), shorty)
  end

  def self.from_ppath(ppath)
    self.decode(ppath.delete('/'))
  end

  private
  def self.split_string_to_dpath(s, dir_length_max)
    s.gsub(/(.{#{dir_length_max}})/) { |m| m + '/' }
  end
end
