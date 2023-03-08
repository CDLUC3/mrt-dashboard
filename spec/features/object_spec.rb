require 'features_helper'
require 'support/presigned'

describe 'objects', js: true do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj
  attr_reader :local_ids
  attr_reader :version_str
  attr_reader :collection_1_id

  attr_reader :producer_files
  attr_reader :system_files

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    @owner = create(:inv_owner, name: 'Owner', ark: 'ark/owner')

    inv_collection_1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @collection_1_id = mock_ldap_for_collection(inv_collection_1)
    mock_permissions_all(user_id, collection_1_id)

    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    inv_collection_1.inv_objects << obj

    @local_ids = Array.new(3) do |i|
      create(:inv_localid, local_id: "local-id-#{i}", inv_object: obj, inv_owner: obj.inv_owner)
    end

    @version_str = "Version #{obj.version_number}"

    @producer_files = Array.new(3) do |i|
      size = 1024 * (2**i)
      create(
        :inv_file,
        inv_object: obj,
        inv_version: obj.current_version,
        pathname: "producer/file #{i}.bin",
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
        inv_version: obj.current_version,
        pathname: "system/file-#{i}.xml",
        full_size: size,
        billable_size: size,
        mime_type: 'text/xml'
      )
    end

    log_in_with(user_id, password)
    click_link(obj.ark)
  end

  after(:each) do
    log_out!
  end

  it 'should be the object page' do
    expect(page.title).to include('Object')
    expect(page.title).to include(obj.ark)
    expect(page).to have_content("Object: #{obj.ark}")
  end

  it 'requires view permissions' do
    user_id = mock_user(name: 'Rachel Roe', password: password)
    expect(obj.user_has_read_permission?(user_id)).to eq(false) # just to be sure

    log_out!
    log_in_with(user_id, password)

    index_path = url_for(
      controller: :object,
      action: :index,
      object: obj.ark,
      only_path: true
    )
    visit(index_path)

    expect(page.title).to include('401')
    expect(page).to have_content('not authorized')
  end

  it 'automatically logs in as guest' do
    mock_permissions_read_only(LDAP_CONFIG['guest_user'], collection_1_id)

    log_out!
    index_path = url_for(
      controller: :object,
      action: :index,
      object: obj.ark,
      only_path: true
    )
    visit(index_path)
    expect(page).to have_content('Logged in as Guest')
    expect(page).to have_content('You must be logged in to access the page you requested')
  end

  it 'requires view permissions even for guest auto-login' do
    expect(obj.user_has_read_permission?(LDAP_CONFIG['guest_user'])).to eq(false) # just to be sure

    log_out!
    index_path = url_for(
      controller: :object,
      action: :index,
      object: obj.ark,
      only_path: true
    )
    visit(index_path)

    expect(page.title).to include('401')
    expect(page).to have_content('not authorized')
  end

  it 'should display minimal metadata' do
    expect(page).to have_content(obj.erc_who)
    expect(page).to have_content(obj.erc_what)
    expect(page).to have_content(obj.erc_when)

    local_ids.each do |lid|
      expect(page).to have_content(lid.local_id)
    end
  end

  it 'should display a download button' do
    download_button = find_button('Download object')
    download_form = download_button.find(:xpath, 'ancestor::form')
    download_action = download_form['action']

    expected_uri = url_for(
      controller: :object,
      action: :presign,
      object: obj
    )
    expect(URI(download_action).path).to eq(URI(expected_uri).path)
  end

  it 'should not display a download button w/o download permission' do
    user_id = mock_user(name: 'Rachel Roe', password: password)
    mock_permissions_view_only(user_id, collection_1_id)

    log_out!
    log_in_with(user_id, password)

    index_path = url_for(
      controller: :object,
      action: :index,
      object: obj.ark,
      only_path: true
    )
    visit(index_path)

    expect(page).not_to have_content('Download object')
    expect(page).to have_content('You do not have permission to download this object.')
  end

  describe 'version info' do
    it 'should display the version' do
      expect(page).to have_content(version_str)
    end

    it 'should let the user navigate to a version' do
      click_link(version_str)
      expect(page).to have_content("#{obj.ark} — #{version_str}")
    end
  end

  describe 'file info' do
    it 'should let the user download each file' do
      producer_files.each do |f|
        basename = f.pathname.sub(%r{^producer/}, '')

        expected_uri = url_for(
          controller: :file,
          action: :presign,
          object: Encoder.urlencode(obj.ark), # TODO: figure out why this needs to be double-encoded, then stop doing it
          version: obj.version_number.to_s,
          file: Encoder.urlencode(f.pathname) # TODO: should we really encode this, or just escape the '/'?
        )

        download_link = find_link(basename)
        expect(download_link).not_to be_nil
        download_href = download_link['href']

        expect(URI(download_href).path).to eq(URI(expected_uri).path)
      end
    end
  end

  describe 'large objects' do
    before :each do
      max_archive_size = APP_CONFIG['max_archive_size']
      file_count = producer_files.size
      producer_files.each do |f|
        f.full_size = (max_archive_size / file_count) + 1
        f.save!
      end
      expect(obj.exceeds_sync_size?).to eq(true) # just to be sure
      expect(obj.exceeds_download_size?).to eq(false) # just to be sure
    end

    describe 'download button' do
      it 'presign object no longer displays the large object email form' do
        mock_assembly(
          obj.node_number,
          ApplicationController.encode_storage_key(obj.ark),
          response_assembly_200('aaa')
        )
        download_button = find_button('Download object')
        download_button.click

        sleep 2

        within('div.ui-dialog div.ui-dialog-titlebar') do
          click_button('Close')
        end

        expect(page.title).not_to include('Large Object')
      end
    end

  end

  describe 'audit_replic info' do
    it 'open audit_replic page' do
      visit "/state/#{CGI.escape(@obj.ark)}/audit_replic.html"
      expect(page.title).to include('Audit Replic Status for Object')
      find('table.state')
      within('table.state') do
        expect(page).to have_selector('thead tr', count: 1)
        expect(page).to have_selector('tbody tr', count: 4)
      end
    end

    it 'open audit_replic page' do
      visit "/state/#{CGI.escape(@obj.ark)}/audit_replic.json"
    end
  end
end
