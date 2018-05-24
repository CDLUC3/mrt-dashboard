require 'features_helper'

describe 'objects' do
  attr_reader :user_id
  attr_reader :password
  attr_reader :obj
  attr_reader :version_str

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

  it 'should display minimal metadata' do
    expect(page).to have_content(obj.erc_who)
    expect(page).to have_content(obj.erc_what)
    expect(page).to have_content(obj.erc_when)
  end

  describe 'version info' do
    it 'should display the version' do
      expect(page).to have_content(version_str)
    end

    it 'should let the user navigate to a version' do
      click_link(version_str)
      expect(page).to have_content("#{obj.ark} - #{version_str}")
    end
  end

  describe 'file info' do
    it 'should display the producer files' do
      producer_files.each do |f|
        basename = f.pathname.sub(/^producer\//, '')
        expect(page).to have_content(basename)
      end
    end

    it 'should let the user download a file' do
      producer_files.each do |f|
        basename = f.pathname.sub(/^producer\//, '')

        expected_uri = url_for(
          controller: 'file',
          action: 'download',
          object: ERB::Util.url_encode(obj.ark), # TODO: figure out why this needs to be double-encoded, then stop doing it
          version: obj.version_number.to_s,
          file: ERB::Util.url_encode(f.pathname) # TODO: should we really encode this, or just escape the '/'?
        )

        download_link = find_link(basename)
        expect(download_link).not_to be_nil
        download_href = download_link['href']

        expect(URI(download_href).path).to eq(URI(expected_uri).path)
      end
    end
  end

end
