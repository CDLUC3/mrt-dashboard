class MrtObject < ActiveRecord::Base
  has_many :mrt_versions
  has_many :mrt_version_metadata, :through=>:mrt_versions
  has_many :mrt_files, :through=>:mrt_versions

  has_many :mrt_collections_mrt_objects
  has_many :mrt_collections, :through => :mrt_collections_mrt_objects

  include Encoder

  def bytestream_uri
    return URI.parse(self.bytestream)
  end
  
  def modified
    return self.last_add_version
  end

  def versions
    return self.mrt_versions
  end

  def current_version
    return self.versions[-1]
  end

  def metadata(name)
    self.current_version.metadata(name)
  end

  def who
    return metadata('who')
  end

  def what
    return metadata('what')
  end

  def when
    return metadata('when')
  end

  def member_of
    return metadata('collection')
  end
    
  def identifier
    return self.primary_id
  end

  # deprecated
  def local_identifier
    return self.local_id
  end

  def permalink
    p = "#{N2T_URI}#{self.primary_id.to_s}"
    return p
  end
  
  def files
    return self.current_version.files
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end

  def ark_urlencode
     return urlencode_mod(self.primary_id)
  end
  
end
