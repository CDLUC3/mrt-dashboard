class InvCollection < ActiveRecord::Base
  has_many :inv_collections_inv_objects
  has_many :inv_objects, through: :inv_collections_inv_objects

  include Encoder

  def to_param
    urlencode(self.ark)
  end

  def group
    @_group ||= Group.find(self.ark)
  end
end
