FactoryBot.define do
  factory :inv_collection do
    ark { ArkHelper.next_ark }

    read_privilege 'public'
    write_privilege 'restricted'
    download_privilege 'public'
    storage_tier 'standard'

    harvest_privilege 'public'

    factory :private_collection do
      read_privilege 'restricted'
      download_privilege 'restricted'
    end
  end
end
