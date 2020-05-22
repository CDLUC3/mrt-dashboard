require 'features_helper'
require 'support/presigned'

# TODO: refactor this to separate logged-in-with-permissions tests from others
describe 'versions', js: true do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj
  attr_reader :version_str
  attr_reader :version
  attr_reader :collection_1_id

  attr_reader :producer_files
  attr_reader :system_files

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    inv_collection_1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_1_id = mock_ldap_for_collection(inv_collection_1)
    mock_permissions_all(user_id, collection_1_id)

    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    inv_collection_1.inv_objects << obj

    @version_str = "Version #{obj.version_number}"
    @version = obj.current_version

    @producer_files = Array.new(3) do |i|
      size = 1024 * (2**i)
      create(
        :inv_file,
        inv_object: obj,
        inv_version: obj.current_version,
        pathname: "producer/file-#{i}.bin",
        full_size: size,
        billable_size: size,
        mime_type: 'application/octet-stream'
      )
    end

    @system_files = Array.new(3) do |i|
      size = 1024 * (2**i)
      create(
        :inv_file,
        inv_object: obj,
        inv_version: version,
        pathname: "system/file-#{i}.xml",
        full_size: size,
        billable_size: size,
        mime_type: 'text/xml'
      )
    end

    log_in_with(user_id, password)
    click_link(obj.ark)
    click_link(version_str)
  end

  after(:each) do
    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button("Close")
    end
    log_out!
  end

  it 'click download button - no mock', js: true do
    click_button('Download version')
    within('#error-dialog') do
      expect(page).to have_content('Internal Server Error') # async
    end
  end

  it 'click download button - has mock', js: true do
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200('aaa')
    )
    click_button('Download version')
    within('.ui-dialog-title') do
      expect(page).to have_content('Preparing Object for Download')
    end
    within('#assembly-dialog h3.h-title') do
      expect(page).to have_content('Object 1 (version 1)') #
    end
  end

end
