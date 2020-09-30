class InvLocalid < ActiveRecord::Base
  belongs_to(:inv_object, class_name: InvObject.name, foreign_key: 'inv_object_ark', primary_key: 'ark')
  belongs_to(:inv_owner, class_name: InvOwner.name, foreign_key: 'inv_owner_ark', primary_key: 'ark')
end
