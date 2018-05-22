FactoryBot.define do
  factory :inv_collection do
    ark { ArkHelper.next_ark }
  end
end
