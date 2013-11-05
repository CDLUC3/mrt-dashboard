class InvFile < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object

  include Encoder

  def identifier
    self.pathname
  end

  def bytestream
    obj = self.inv_object
    "#{URI_1}#{obj.node_number}/#{obj.ark_urlencode}/#{self.inv_version.number}/#{self.file_urlencode}"
  end

  def bytestream_uri
    URI.parse(self.bytestream)
  end
  
  #this value may not be a SHA-1 digest value 
  def message_digest
    self.digest_value
  end

  def file_urlencode
    urlencode_mod(self.pathname)
  end
end
