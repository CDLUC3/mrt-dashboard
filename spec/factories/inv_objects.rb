FactoryGirl.define do 
  factory :inv_object do |f|
    f.id "6228"
    f.inv_owner_id "6"
    f.ark "ark:/99999/fk4qv5n4z"
    f.object_type "MRT-curatorial"
    f.role "MRT-content"
    f.aggregate_role "MRT-none"
    f.version_number "1"
    f.erc_who "(:unas)"
    f.erc_what "Robotic Workstation"
    f.erc_when "(:unas)"
    f.erc_where "ark:/99999/fk4qv5n4z ; (:unas)"
    f.created "2013-08-09 14:41:23"
    f.modified "2013-08-09 14:41:34"
    f.inv_versions { |a|  [ a.association(:inv_version) ] }
  end

  factory :inv_collections_inv_object do
    association :inv_object, :factory => :inv_object
    association :inv_collection, :factory => :demo_collection
  end
end
