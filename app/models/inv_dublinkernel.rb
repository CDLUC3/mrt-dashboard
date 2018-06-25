class InvDublinkernel < ActiveRecord::Base
  belongs_to :inv_version
  belongs_to :inv_object
  has_one :sha_dublinkernel, foreign_key: 'id', inverse_of: :inv_dublinkernel
end
