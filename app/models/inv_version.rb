class InvVersion < ActiveRecord::Base
  belongs_to :inv_object
  has_many :inv_files
  has_many :inv_dublinkernels

  def to_param
    self.number
  end

  def permalink
    "#{MERRITT_SERVER}/m/#{self.inv_object.to_param}/#{self.to_param}"
  end
  
  def bytestream_uri 
    URI.parse("#{URI_1}#{self.inv_object.node_number}/#{self.inv_object.to_param}/#{self.to_param}")
  end

  def total_size
    InvFile.where("inv_version_id = ?", self.id).sum("full_size")
  end

  def system_files 
    self.inv_files.select {|f| f.pathname.match(/^system\//) }.
      sort_by {|x| File.basename(x.pathname.downcase) }
  end

  def producer_files 
    self.inv_files.select {|f| f.pathname.match(/^producer\//) }.
      sort_by {|x| File.basename(x.pathname.downcase) }
  end

  def metadata(element)
    self.inv_dublinkernels.select {|md| md.element == element }.map {|md| md.value }
  end

  def erc_who
    self.metadata('who')[0]
  end

  def erc_what
    self.metadata('what')[0]
  end

  def erc_when
    self.metadata('when')[0]
  end

  def erc_where
    self.metadata('where')[0]
  end
end
