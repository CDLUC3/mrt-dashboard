class InvFile < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object

  include Encoder

  def to_param
    urlencode_mod(self.pathname)
  end
  
  def bytestream
    "#{URI_1}#{self.inv_object.node_number}/#{self.inv_object.to_param}/#{self.inv_version.number}/#{self.to_param}"
  end

  def bytestream_uri
    URI.parse(self.bytestream)
  end
  
  #this value may not be a SHA-1 digest value 
  def message_digest
    self.digest_value
  end
end
