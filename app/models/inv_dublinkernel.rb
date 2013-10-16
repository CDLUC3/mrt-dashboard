class InvDublinkernel < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object
end