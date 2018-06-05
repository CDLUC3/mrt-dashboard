FactoryBot.define do
  factory :inv_embargo do
    embargo_end_date { Time.now }
  end
end
