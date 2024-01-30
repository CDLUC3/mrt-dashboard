require 'features_helper'
require 'support/presigned'

# TODO: refactor this to separate logged-in-with-permissions tests from others
describe 'presigned objects and versions', js: true do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj
  attr_reader :version_str
  attr_reader :version
  attr_reader :collection_1_id

  attr_reader :producer_files
  attr_reader :system_files
  attr_reader :token

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

  before(:each) do
    @token = SecureRandom.uuid
  end

  after(:each) do
    if has_css?('div.ui-dialog')
      within('div.ui-dialog div.ui-dialog-titlebar') do
        click_button('Close')
      end
    end
    log_out!
  end

  it 'click download button - no mock storage service available', js: true do
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      general_response_500
    )
    click_button('Download version')
    # this is a real (not mocked) ajax call
    sleep 1
    find('div.ui-dialog')
    within('div.ui-dialog') do
      expect(page).to have_content('Internal Server Error') # async
    end
  end

  it 'click download button - mocked call to the storage service', js: true do
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200(@token)
    )
    click_button('Download version')
    sleep 1
    find('div.ui-dialog')
    within('.ui-dialog-title') do
      expect(page).to have_content('Preparing Object for Download')
    end
    within('#assembly-dialog h3.h-title') do
      expect(page).to have_content('Object 1 (version 1)')
    end
  end

  it 'test close dialog and look at upper downloads button (not ready)' do
    within('#downloads') do
      expect(page).to have_content('Downloads: None')
    end
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200(@token)
    )
    click_button('Download version')
    sleep 5
    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button('Close')
    end
    within('#downloads') do
      expect(page.text).to match(/Downloads: [0-9]+%*/)
    end
  end

  it 'test close dialog and look at upper downloads button (ready)', js: true do
    within('#downloads') do
      expect(page).to have_content('Downloads: None')
    end
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200(@token, 10)
    )

    click_button('Download version')

    sleep 2
    within('div.ui-dialog .ui-dialog-title') do
      expect(page.text).to eq('Preparing Object for Download')
    end

    page.execute_script("presignDialogs.simulateCompletion('#{@token}', '#pretend-link')")
    sleep 2

    within('div.ui-dialog .ui-dialog-title') do
      expect(page.text).to eq('Object is ready for Download')
    end
    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button('Close')
    end
    within('#downloads') do
      expect(page.text).to eq('Downloads: Available')
    end
  end

  it 'test close/reopen dialog from upper downloads button' do
    mock_assembly_with_download(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200(@token, 10)
    )

    fname = "#{@obj.ark} Version #{@version.number}"
    filename = "#{fname.gsub(/[^A-Za-z0-9]+/, '_')}.zip"

    click_button('Download version')

    sleep 2

    page.execute_script("presignDialogs.simulateCompletion('#{@token}', '#pretend-link')")

    sleep 2

    within('div.ui-dialog div.ui-dialog-buttonset') do
      click_button('Close')
    end

    within('#downloads') do
      expect(page.text).to eq('Downloads: Available')
    end

    click_button('Downloads: Available')

    sleep 2

    page.execute_script("presignDialogs.simulateCompletion('#{@token}', '#pretend-link')")

    sleep 2

    within('div.ui-dialog:has(div.ui-dialog-buttonset) .ui-dialog-title') do
      expect(page.text).to eq('Object is ready for Download')
    end

    click_link(filename)

    within('#downloads') do
      expect(page.text).to eq('Downloads: None')
    end

  end

  it 'test no downloads' do
    click_button('Downloads: None')
    find('div.ui-dialog')
    within('div.ui-dialog') do
      expect(page).to have_content('No download assembly is in progress.') # async
    end
  end

  it 'test close/reopen dialog from new download button (same object)' do
    mock_assembly(
      @obj.node_number,
      ApplicationController.encode_storage_key(@obj.ark, @version.number),
      response_assembly_200(@token, 10)
    )

    click_button('Download version')

    sleep 2

    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button('Close')
    end

    click_button('Download version')

    within('div.ui-dialog .ui-dialog-title') do
      expect(page.text).to eq('Preparing Object for Download')
    end
  end

  it 'test close/reopen dialog from new download button (different object)' do
    mock_assembly(
      obj.node_number,
      ApplicationController.encode_storage_key(obj.ark, version.number),
      response_assembly_200(token, 10)
    )

    click_button('Download version')

    sleep 2

    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button('Close')
    end

    click_link(obj.ark)

    mock_assembly(
      obj.node_number,
      ApplicationController.encode_storage_key(obj.ark),
      response_assembly_200(token, 10)
    )

    click_button('Download object')

    sleep 1

    within('div.ui-dialog .ui-dialog-title') do
      expect(page.text).to eq('Replace Object Being Prepared for Download?')
    end

    within('#download-in-progress') do
      within('.presign-title') do
        expect(page.text).to eq('Object 1; Object 1 (version 1)')
      end

      within('h3.h-check-title') do
        expect(page.text).to eq('Title: Object 1; Object 1')
      end
    end

    click_button('Continue Previous Download')

    sleep 1

    within('#assembly-dialog h3.h-title') do
      expect(page.text).to eq('Title: Object 1; Object 1 (version 1)')
    end

    within('div.ui-dialog div.ui-dialog-titlebar') do
      click_button('Close')
    end

    click_button('Download object')

    sleep 1

    within('div.ui-dialog .ui-dialog-title') do
      expect(page.text).to eq('Replace Object Being Prepared for Download?')
    end

    within('#download-in-progress') do
      within('h3.h-check-title') do
        expect(page.text).to eq('Title: Object 1; Object 1')
      end
    end

    click_button('Download Current Object')

    sleep 1

    # NOTE: cannot successfully mock the download initiated from javascript

    # mock_assembly(
    #   @obj.node_number,
    #   ApplicationController.encode_storage_key(@obj.ark),
    #   response_assembly_200
    # )

    # within('#assembly-dialog h3.h-title') do
    #   expect(page.text).to eq('Title: Object 1; Object 1 (version 1)')
    # end
  end

end
