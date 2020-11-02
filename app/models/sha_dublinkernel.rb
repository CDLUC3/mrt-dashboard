class ShaDublinkernel < ApplicationRecord
  belongs_to :inv_dublinkernel, foreign_key: 'id', inverse_of: :sha_dublinkernel
end
