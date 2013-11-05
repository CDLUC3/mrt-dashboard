class InvCollectionsInvObject < ActiveRecord::Base
  belongs_to :inv_collection
  belongs_to :inv_object
end
