class InvObject < ActiveRecord::Base
  has_many :inv_versions
  has_many :inv_files
  
  has_many :inv_dublinkernels

  has_many :inv_collections_inv_objects
  has_many :inv_collections, :through => :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, :through => :inv_nodes_inv_objects

  include Encoder

  def to_param
    self.ark_urlencode
  end

  def bytestream_uri
    URI.parse("#{URI_1}#{self.node_number}/#{self.ark_urlencode}")
  end

  def node_number
    InvNode.joins(:inv_nodes_inv_objects).select("number").where("role = ?", "primary").limit(1).map(&:number)[0]
  end

  def size
    InvFile.where("inv_object_id = ?", self.id).sum("billable_size")
  end
 
  def total_actual_size
    InvFile.where("inv_object_id = ?", self.id).sum("full_size")
  end
  
  def storage_url
    self.bytestream_uri
  end

  def versions
    self.inv_versions
  end

  def current_version
    self.versions[-1]
  end

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
    "#{N2T_URI}#{self.ark.to_s}"
  end
  
  def files
    self.current_version.files
  end

  def system_files 
    self.files.select {|f| f.pathname.match(/^system\//) }
  end

  def producer_files 
    self.files.select {|f| f.pathname.match(/^producer\//) }
  end

  def ark_urlencode
    urlencode_mod(self.ark)
  end
end
