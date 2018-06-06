FactoryBot.define do
  factory :inv_dublinkernel do
    # noinspection RubyArgCount
    after(:create) do |inv_dk|
      value = inv_dk.value
      if value != '(:unas)'
        create(:sha_dublinkernel, inv_dublinkernel: inv_dk, value: value)
      end
    end
  end
end
