FactoryBot.define do
  factory :sha_dublinkernel do
    inv_dublinkernel
  end

  # # noinspection RubyArgCount
  # after(:create) do |_|
  #   # rebuild fulltext index
  #   ApplicationRecord.connection.execute('OPTIMIZE TABLE sha_dublinkernels')
  # end
end
