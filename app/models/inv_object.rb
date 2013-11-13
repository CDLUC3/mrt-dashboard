class InvObject < ActiveRecord::Base
  has_many :inv_versions, :inverse_of => :inv_object
  has_many :inv_files, :through => :inv_versions
  
  has_many :inv_dublinkernels

  has_many :inv_collections_inv_objects
  has_many :inv_collections, :through => :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, :through => :inv_nodes_inv_objects

  include Encoder

  def to_param
    urlencode(self.ark)
  end

  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{self.node_number}/#{self.to_param}")
  end

  def dua_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{self.node_number}/#{self.inv_collection.to_param}/0/#{urlencode(APP_CONFIG['mrt_dua_file'])}")
  end

  def node_number
    InvNode.joins(:inv_nodes_inv_objects).select("number").where("role = ?", "primary").limit(1).map(&:number)[0]
  end

  def size
    self.inv_files.sum("billable_size")
  end
 
  def total_actual_size
    self.inv_files.sum("full_size")
  end

  def current_version
    self.inv_versions.order("number desc").first
  end
  
  def inv_collection
    self.inv_collections.first
  end

  def group
    @_group ||= Group.find(self.inv_collection.ark)
  end
  
  def permalink
    "#{APP_CONFIG['n2t_uri']}#{self.ark.to_s}"
  end
end
