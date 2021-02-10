FactoryBot.define do
  factory :inv_file do

    full_size { 0 }
    billable_size { 0 }
    created { Time.now }

    # noinspection RubyArgCount
    after(:build) do |file, evaluator|
      source = evaluator.pathname.start_with?('system') ? 'system' : 'producer'
      file.source ||= source
      file.role ||= source == 'producer' ? 'metadata' : 'data'
    end
  end
end
