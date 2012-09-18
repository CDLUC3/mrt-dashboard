class MrtObject < ActiveRecord::Base
  has_many :mrt_versions
  has_many :mrt_version_metadata, :through=>:mrt_versions
  has_many :mrt_files, :through=>:mrt_versions

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

  def who
    return self.current_version.who
  end

  def what
    return self.current_version.what
  end

  def when
    return self.current_version.when
  end

  def member_of
    return self.current_version.member_of
  end
    
  def identifier
    return self.primary_id
  end

  # deprecated
  def local_identifier
    return self.local_id
  end

  def permalink
    return "#{N2T_URI}#{identifier.to_s}"
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

end
