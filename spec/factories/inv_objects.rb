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
      version = create(:inv_version, inv_object: obj)
      [
        [1, 'who', nil, :erc_who],
        [2, 'what', nil, :erc_what],
        [3, 'when', nil, :erc_when],
        [4, 'where', 'primary', :ark],
        [5, 'where', 'local', :erc_where]
      ].each do |seq_num, element, qualifier, accessor|
        value = obj.send(accessor)
        create(
          :inv_dublinkernel,
          inv_object: obj,
          inv_version: version,
          seq_num: seq_num,
          element: element,
          qualifier: qualifier,
          value: value
        )
      end
    end
  end
end
