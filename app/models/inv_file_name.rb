class InvFileName < ApplicationRecord
  belongs_to :inv_version
  belongs_to :inv_object
  belongs_to :inv_file
end
