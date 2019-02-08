class InvOwner < ActiveRecord::Base
  has_many :inv_objects
end
