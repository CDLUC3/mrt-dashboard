require 'features_helper'

describe 'versions' do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj
  attr_reader :version_str
  attr_reader :version

  attr_reader :producer_files
  attr_reader :system_files

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)

    inv_collection_1 = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    collection_1_id = mock_ldap_for_collection(inv_collection_1)
    mock_permissions_all(user_id, collection_1_id)

    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    inv_collection_1.inv_objects << obj

    @version_str = "Version #{obj.version_number}"
    @version = obj.current_version

    @producer_files = Array.new(3) do |i|
      size = 1024 * (2 ** i)
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
      size = 1024 * (2 ** i)
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

  it 'should link back to the object' do
    click_link("Object: #{obj.ark}")
    expect(page.title).to include('Object')
    expect(page.title).to include(obj.ark)
  end

  describe 'files' do
    it 'should let the user download both system and producer files' do
      all_files = producer_files + system_files
      all_files.each do |f|
        basename = f.pathname.sub(/^(producer|system)\//, '')

        expected_uri = url_for(
          controller: :file,
          action: :download,
          object: ERB::Util.url_encode(obj.ark), # TODO: figure out why this needs to be double-encoded, then stop doing it
          version: obj.version_number.to_s,
          file: ERB::Util.url_encode(f.pathname) # TODO: should we really encode this, or just escape the '/'?
        )
        # TODO: figure out why this is only half-double-encoded, unlike the object page
        expected_uri = CGI.unescape(expected_uri)

        download_link = find_link(basename)
        expect(download_link).not_to be_nil
        download_href = download_link['href']

        expect(URI(download_href).path).to eq(URI(expected_uri).path)
      end
    end
  end

end
