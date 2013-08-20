class InvObject < ActiveRecord::Base


  has_many :inv_versions
  has_many :inv_files
  
  has_many :inv_dublinkernels

  has_many :inv_collections_inv_objects
  has_many :inv_collections, :through => :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, :through => :inv_nodes_inv_objects

  include Encoder

  def bytestream_uri
    @ark = self.ark_urlencode
    @node_number = self.node_number
    @bytestream = "#{URI_1}" + "#{@node_number}" + "/"+ "#{@ark}"
    return URI.parse(@bytestream)
  end

  def node_number
    @node_number = InvNode.joins(:inv_nodes_inv_objects).select("number").where("role = ?", "primary").limit(1).map(&:number)[0]
  end

  def size
    @size = InvFile.where("inv_object_id = ?", self.id).sum("billable_size")
  end
 
  def total_actual_size
   @total_actual_size = InvFile.where("inv_object_id = ?", self.id).sum("full_size")
  end
  
  def storage_url
    @storage_url = self.bytestream_uri
  end

  # def modified
  #   return self.modified
  # end

  def versions
    return self.inv_versions
  end

  def current_version
    return self.versions[-1]
  end

  # def metadata_type(element)
  #   @metadata_type = "erc_" + "#{element}"
  # end

  # def metadata(element)
  #   #self.current_version.inv_dublinkernel(element)
  #   self.metadata_type(element)
  # end

  def who
    self.erc_who
  end

  def what
    self.erc_what
  end

  def when
    self.erc_when
  end

   def member_of
  #   return metadata('collection')
    self.inv_collections.first.ark
   end
    
  def identifier
    self.ark
  end

  # deprecated
  def local_identifier
    self.erc_where
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

  def ark_urlencode
     return urlencode_mod(self.ark)
  end
  
end
