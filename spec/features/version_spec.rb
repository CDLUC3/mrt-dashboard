require 'features_helper'

# TODO: refactor this to separate logged-in-with-permissions tests from others
describe 'versions' do
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
    log_out!
  end

  it 'should be the version page' do
    expect(page.title).to include(version_str)
    expect(page.title).to include(obj.ark)
  end

  it 'requires view permissions' do
    user_id = mock_user(name: 'Rachel Roe', password: password)
    expect(obj.user_has_read_permission?(user_id)).to eq(false) # just to be sure

    log_out!
    log_in_with(user_id, password)

    index_path = url_for(
      controller: :version,
      action: :index,
      object: obj.ark,
      version: version.number,
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
      controller: :version,
      action: :index,
      object: obj.ark,
      version: version.number,
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
      controller: :version,
      action: :index,
      object: obj.ark,
      version: version.number,
      only_path: true
    )
    visit(index_path)

    expect(page.title).to include('401')
    expect(page).to have_content('not authorized')
  end

  describe 'without specified version' do
    it 'redirects to the latest' do
      create(:inv_version, inv_object: obj, number: 2)
      obj.version_number = 2
      obj.save!

      index_path = url_for(controller: :version, action: :index, object: obj.ark, only_path: true)
      visit(index_path)
      expect(page.title).to include('Version 2')
      expect(page.title).to include(obj.ark)
    end
  end

  it 'should display a download button' do
    download_button = find_button('Download version')
    download_form = download_button.find(:xpath, 'ancestor::form')
    download_action = download_form['action']

    expected_uri = url_for(
      controller: :version,
      action: :download,
      object: obj,
      version: version
    )
    expect(URI(download_action).path).to eq(URI(expected_uri).path)
  end

  it 'should not display a download button w/o download permission' do
    user_id = mock_user(name: 'Rachel Roe', password: password)
    mock_permissions_view_only(user_id, collection_1_id)

    log_out!
    log_in_with(user_id, password)

    index_path = url_for(
      controller: :version,
      action: :index,
      object: obj.ark,
      version: version.number,
      only_path: true
    )
    visit(index_path)

    expect(page).not_to have_content('Download version')
    expect(page).to have_content('You do not have permission to download this object.')
  end

  it 'should not link files w/o download permission' do
    user_id = mock_user(name: 'Rachel Roe', password: password)
    mock_permissions_view_only(user_id, collection_1_id)

    log_out!
    log_in_with(user_id, password)

    index_path = url_for(
      controller: :version,
      action: :index,
      object: obj.ark,
      version: version.number,
      only_path: true
    )
    visit(index_path)

    all_files = producer_files + system_files
    all_files.each do |f|
      basename = f.pathname.sub(%r{^(producer|system)/}, '')
      expect(page).not_to have_link(basename)
    end
  end

  it 'should link back to the object' do
    click_link("Object: #{obj.ark}")
    expect(page.title).to include('Object')
    expect(page.title).to include(obj.ark)
  end

  describe 'files' do
    it 'should let the user download both system and producer files' do
      all_files = producer_files + system_files
      all_files.each do |f|
        basename = f.pathname.sub(%r{^(producer|system)/}, '')

        expected_uri = url_for(
          controller: :file,
          action: :presign,
          object: ERB::Util.url_encode(obj.ark), # TODO: figure out why this needs to be double-encoded, then stop doing it
          version: obj.version_number.to_s,
          file: ERB::Util.url_encode(f.pathname) # TODO: should we really encode this, or just escape the '/'?
        )
        # TODO: figure out why this is only half-double-encoded, unlike the object page
        expected_uri = CGI.unescape(expected_uri)

        expect(page).to have_link(basename)
        download_link = find_link(basename)
        download_href = download_link['href']

        expect(URI(download_href).path).to eq(URI(expected_uri).path)
      end
    end
  end

end
