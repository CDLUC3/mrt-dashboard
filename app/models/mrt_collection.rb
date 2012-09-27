class MrtCollection < ActiveRecord::Base
  has_and_belongs_to_many :mrt_objects
end
