FactoryBot.define do
  factory :inv_dublinkernel do
    # noinspection RubyArgCount
    after(:create) do |inv_dk|
      value = inv_dk.value
      create(:sha_dublinkernel, inv_dublinkernel: inv_dk, value: value) if value != '(:unas)'
    end
  end
end
