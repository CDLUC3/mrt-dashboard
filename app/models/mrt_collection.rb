class MrtCollection < ActiveRecord::Base
  has_many :mrt_collections_mrt_objects
  has_many :mrt_objects, :through => :mrt_collections_mrt_objects
end
