class InvFile < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object

  include Encoder

  def identifier
    self.pathname
  end

  def to_param
    urlencode_mod(self.pathname)
  end
  
  def bytestream
    obj = self.inv_object
    "#{URI_1}#{obj.node_number}/#{obj.to_param}/#{self.inv_version.number}/#{self.to_param}"
  end

  def bytestream_uri
    URI.parse(self.bytestream)
  end
  
  #this value may not be a SHA-1 digest value 
  def message_digest
    self.digest_value
  end
end
