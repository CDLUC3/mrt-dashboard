class InvNode < ActiveRecord::Base
  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, through: :inv_nodes_inv_objects
end
