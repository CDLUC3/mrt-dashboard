class MrtFile < ActiveRecord::Base
  belongs_to :mrt_version

  include Encoder

  # TODO deprecated
  def identifier
    return self.filename
  end

  def bytestream_uri
    return URI.parse(self.bytestream)
  end
  
  def message_digest
    return self.sha1
  end

  def file_urlencode
     return urlencode_mod(self.identifier)
  end

end
