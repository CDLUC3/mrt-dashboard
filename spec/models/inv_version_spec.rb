require 'rails_helper'

describe InvVersion do
  include MerrittRetryMixin

  attr_reader :obj, :version

  before(:each) do
    collection = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
    @obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    collection.inv_objects << obj
    @version = obj.current_version
  end

  describe :bytestream_uri do
    it 'generates the "uri_1" (content) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_1']}#{obj.node_number}/#{obj.to_param}/#{version.to_param}"
      expect(version.bytestream_uri).to eq(URI.parse(expected_uri))
    end
  end

  describe :bytestream_uri_2 do
    it 'generates the "uri_2" (producer) URI' do
      # TODO: figure out why this produces double //s and stop doing it
      expected_uri = "#{APP_CONFIG['uri_2']}#{obj.node_number}/#{obj.to_param}/#{version.to_param}"
      expect(version.bytestream_uri2).to eq(URI.parse(expected_uri))
    end
  end

  describe 'retry logic' do
    it 'total_size retry' do
      allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
        .to receive(:sum)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        @version.total_size
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'system_files retry' do
      allow_any_instance_of(InvVersion)
        .to receive(:inv_files)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        @version.system_files
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'producer_files retry' do
      allow_any_instance_of(InvVersion)
        .to receive(:inv_files)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        @version.producer_files
      end.to raise_error(MerrittRetryMixin::RetryException)
    end

    it 'metadata retry' do
      allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
        .to receive(:select)
        .with(any_args)
        .and_raise(Mysql2::Error::ConnectionError.new('Simulate Failure'))

      expect do
        @version.metadata('who')
      end.to raise_error(MerrittRetryMixin::RetryException)
    end
  end
end
