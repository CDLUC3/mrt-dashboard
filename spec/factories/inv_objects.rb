FactoryBot.define do
  factory :inv_object do
    ark { ArkHelper.next_ark }
    object_type 'MRT-curatorial'
    role 'MRT-content'

    erc_who '(:unas)'
    erc_what '(:unas)'
    erc_when '(:unas)'
    erc_where '(:unas)' # TODO: can we access the ark here?
  end
end
