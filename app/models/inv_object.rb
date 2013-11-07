class InvObject < ActiveRecord::Base
  has_many :inv_versions
  
  has_many :inv_dublinkernels

  has_many :inv_collections_inv_objects
  has_many :inv_collections, :through => :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, :through => :inv_nodes_inv_objects

  include Encoder

  def to_param
    urlencode_mod(self.ark)
  end

  def bytestream_uri
    URI.parse("#{URI_1}#{self.node_number}/#{self.to_param}")
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

  def current_version
    self.inv_versions[-1]
  end
  
  def inv_collection
    self.inv_collections.first
  end

  def group
    @_group ||= Group.find(self.inv_collection.ark)
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
end
