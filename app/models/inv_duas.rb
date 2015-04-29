class InvDuas < ActiveRecord::Base
  belongs_to :inv_object
  has_one :sha_duas, :foreign_key => "id", :inverse_of => :inv_duas
end
