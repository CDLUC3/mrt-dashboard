FactoryBot.define do
  factory :inv_object do
    ark { ArkHelper.next_ark('object') }

    inv_owner

    object_type 'MRT-curatorial'
    role 'MRT-content'

    version_number 1

    erc_who '(:unas)'
    erc_what '(:unas)'
    erc_when '(:unas)'
    erc_where '(:unas)' # TODO: can we access the ark here?

    created { Time.now }
    modified { Time.now }

    # noinspection RubyArgCount
    after(:create) do |obj|
      create(:inv_version, inv_object: obj)
    end
  end
end
