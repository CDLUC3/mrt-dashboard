FactoryBot.define do
  factory :inv_version do
    ark { ArkHelper.next_ark('version') }

    number 1

    created { Time.now }

    # noinspection RubyArgCount
    after(:create) do |version|
      obj = version.inv_object
      {
        'who' => obj.erc_who,
        'what' => obj.erc_what,
        'when' => obj.erc_when,
        'where' => obj.erc_where
      }.each_with_index do |(element, value), seq_num|
        create(
          :inv_dublinkernel,
          inv_object: obj,
          inv_version: version,
          element: element,
          value: value,
          seq_num: seq_num
        )
      end

    end
  end
end
