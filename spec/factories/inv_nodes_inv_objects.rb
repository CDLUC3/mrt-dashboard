FactoryBot.define do
  factory :inv_nodes_inv_object do
    role { 'primary' }

    created { Time.now }
  end
end
