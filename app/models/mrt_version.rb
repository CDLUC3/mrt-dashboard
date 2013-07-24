class MrtVersion < ActiveRecord::Base
  belongs_to :mrt_object
  has_many :mrt_files
  has_many :mrt_version_metadata

  def identifier
    return self.version_number.to_s
  end

  def bytestream_uri
    return URI.parse(self.bytestream)
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def metadata(name)
    self.mrt_version_metadata.select {|md| md.name == name }.map {|md| md.value }
  end

  def files
    return self.mrt_files
  end

  def who
    return self.metadata('who')
  end

  def member_of
    return self.metadata('collection')
  end

  def what
    return self.metadata('what')
  end

  def when
    return self.metadata('when')
  end
end
