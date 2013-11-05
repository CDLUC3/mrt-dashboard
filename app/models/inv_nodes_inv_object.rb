class InvNodesInvObject < ActiveRecord::Base
  belongs_to :inv_node
  belongs_to :inv_object
end