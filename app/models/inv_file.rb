class InvFile < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object

  include Encoder

  def identifier
    self.pathname
  end

  def bytestream
    @obj = self.inv_object
    @obj_ark = @obj.ark_urlencode
    @node_number = @obj.node_number
    @version_number = self.inv_version.number
    @file_pathname = self.file_urlencode
    @bytestream = "#{URI_1}" + "#{@node_number}" + "/"+ "#{@obj_ark}" + "/"+ "#{@version_number}" + "/"+ "#{@file_pathname}"
  end

  def bytestream_uri
    return URI.parse(self.bytestream)
  end
  
  #this value may not be a SHA-1 digest value 
  def message_digest
    return self.digest_value
  end

  def file_urlencode
     return urlencode_mod(self.pathname)
  end

end