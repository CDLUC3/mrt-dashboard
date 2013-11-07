class InvFile < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object

  include Encoder

  def to_param
    urlencode_mod(self.pathname)
  end
  
  def bytestream_uri
    URI.parse("#{URI_1}#{self.inv_object.node_number}/#{self.inv_object.to_param}/#{self.inv_version.number}/#{self.to_param}")
  end
end
