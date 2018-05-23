require 'features_helper'

describe 'objects' do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    inv_collection_1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    collection_1_id = mock_ldap_for_collection(inv_collection_1)
    mock_permissions_all(user_id, collection_1_id)

    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    inv_collection_1.inv_objects << obj

    log_in_with(user_id, password)
    click_link(obj.ark)
  end

  it 'should display minimal metadata' do
    expect(page).to have_content(obj.erc_who)
    expect(page).to have_content(obj.erc_what)
    expect(page).to have_content(obj.erc_when)
  end

  it 'should display a link to the version' do
    expect(page).to have_content("Version #{obj.version_number}")
  end
end
