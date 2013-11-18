class InvCollection < ActiveRecord::Base
  has_many :inv_collections_inv_objects
  has_many :inv_objects, :through => :inv_collections_inv_objects
end
