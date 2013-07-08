class MrtCollectionsMrtObject < ActiveRecord::Base
  belongs_to :mrt_collection
  belongs_to :mrt_object
end
