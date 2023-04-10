class InvOwner < ApplicationRecord
  has_many :inv_objects, inverse_of: :inv_owner
end
