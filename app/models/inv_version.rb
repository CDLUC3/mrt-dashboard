class InvVersion < ActiveRecord::Base

  belongs_to :inv_object
  has_many :inv_files
  has_many :inv_dublinkernels

  def identifier
    return self.number.to_s
  end

  def bytestream_uri 
    @obj = self.inv_object
    @obj_ark = @obj.ark_urlencode
    @node_number = @obj.node_number
    @version_number = self.number
    @bytestream = "#{URI_1}" + "#{@node_number}" + "/"+ "#{@obj_ark}" + "/"+ "#{@version_number}" 

    return URI.parse(@bytestream)
  end

  def total_size
   @total_size = InvFile.where("inv_version_id = ?", self.id).sum("full_size")
  end

  def system_files 
    self.files.select {|f| f.identifier.match(/^system\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def producer_files 
    self.files.select {|f| f.identifier.match(/^producer\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def metadata(element)
    self.inv_dublinkernels.select {|md| md.element == element }.map {|md| md.value }
  end

  def files
    self.inv_files
  end

  def who
    self.metadata('who')[0]
  end

  def member_of
    self.inv_object.inv_collections.first.ark
  end

  def what
    self.metadata('what')[0]
  end

  def when
    self.metadata('when')[0]
  end
 end
