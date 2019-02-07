class InvLocalid < ActiveRecord::Base
  belongs_to(:inv_object_ark, class_name: InvObject)
end