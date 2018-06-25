FactoryBot.define do
  factory :inv_owner do
    ark { ArkHelper.next_ark('owner') }
  end
end
