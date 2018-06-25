require 'rails_helper'

class LdapStub
  include LdapMixin
end

describe LdapMixin do
  attr_reader :base
  attr_reader :init_hash
  attr_reader :ldap
  attr_reader :admin_ldap

  before(:each) do
    unmock_ldap!

    @base = 'ou=People,ou=uc3,dc=example,dc=edu'

    @init_hash = {
      host: LDAP_CONFIG['host'],
      port: LDAP_CONFIG['port'],
      base: base,
      admin_user: LDAP_CONFIG['admin_user'],
      admin_password: LDAP_CONFIG['admin_password'],
      minter: 'http://noid.example.edu/minter',
      connect_timeout: LDAP_CONFIG['connect_timeout']
    }
    @ldap = LdapStub.new(init_hash)

    ldap_params = {
      host: LDAP_CONFIG['host'],
      port: LDAP_CONFIG['port'],
      auth: {
        method: :simple,
        username: LDAP_CONFIG['admin_user'],
        password: LDAP_CONFIG['admin_password']
      },
      encryption: {
        method: :simple_tls,
        tls_options: {
          ssl_version: 'TLSv1_1'
        }
      },
      connect_timeout: LDAP_CONFIG['connect_timeout']
    }

    @admin_ldap = double(Net::LDAP)
    allow(Net::LDAP).to receive(:new).with(ldap_params).and_return(admin_ldap)

    allow(ldap).to receive(:obj_filter) { |id| Net::LDAP::Filter.eq('foo', id) }
    allow(ldap).to receive(:ns_dn) { |id| "foo=#{id},#{base}" }
  end

  it 'tries to bind immediately unless env is test' do
    old_env = ENV['RAILS_ENV']
    begin
      ENV['RAILS_ENV'] = 'production'
      expect(admin_ldap).to receive(:bind).and_return(false)
      expect { LdapStub.new(init_hash) }.to raise_error(LdapMixin::LdapException, 'Unable to bind to LDAP server.')
    ensure
      ENV['RAILS_ENV'] = old_env
    end
  end

  describe ':delete_record' do
    it 'raises for records that don\'t exist' do
      id = 'foo'
      expect(admin_ldap).to receive(:search).with(base: base, filter: ldap.obj_filter(id)).and_return([])
      expect { ldap.delete_record(id) }.to raise_error(LdapMixin::LdapException, 'id does not exist')
    end

    it 'deletes records' do
      id = 'foo'
      expect(admin_ldap).to receive(:search).with(base: base, filter: ldap.obj_filter(id)).and_return(['bar'])
      expect(admin_ldap).to receive(:delete).with(dn: ldap.ns_dn(id)).and_return(true)
      ldap.delete_record(id)
    end
  end

  describe ':add_attribute' do
    it 'adds an attribute' do
      id = 'foo'
      attribute = :bar
      value = 'baz'
      expect(admin_ldap).to receive(:add_attribute).with(ldap.ns_dn(id), attribute, value)
      ldap.add_attribute(id, attribute, value)
    end
  end

  describe ':replace_attribute' do
    it 'replaces an attribute' do
      id = 'foo'
      attribute = :bar
      value = 'baz'
      expect(admin_ldap).to receive(:replace_attribute).with(ldap.ns_dn(id), attribute, value)
      ldap.replace_attribute(id, attribute, value)
    end
  end

  describe ':delete_attribute' do
    it 'deletes an attribute' do
      id = 'foo'
      attribute = :bar
      expect(admin_ldap).to receive(:delete_attribute).with(ldap.ns_dn(id), attribute)
      ldap.delete_attribute(id, attribute)
    end
  end

  describe ':delete_attribute_value' do
    it 'deletes an attribute' do
      id = 'foo'
      attribute = :bar
      value = 'baz'
      expect(admin_ldap).to receive(:search).with(base: base, filter: ldap.obj_filter(id)).and_return([{ bar: ['qux', value, 'corge'] }])
      expect(admin_ldap).to receive(:replace_attribute).with(ldap.ns_dn(id), attribute, ['qux', 'corge'])
      ldap.delete_attribute_value(id, attribute, value)
    end

    it 'ignores different values' do
      id = 'foo'
      attribute = :bar
      value = 'baz'
      expect(admin_ldap).to receive(:search).with(base: base, filter: ldap.obj_filter(id)).and_return([{ bar: ['qux', 'grault', 'corge'] }])
      expect(admin_ldap).to receive(:replace_attribute).with(ldap.ns_dn(id), attribute, ['qux', 'grault', 'corge'])
      ldap.delete_attribute_value(id, attribute, value)
    end
  end

  describe ':fetch' do
    it 'fetches by id' do
      id = 'foo'
      results = [1]
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: ldap.obj_filter(id)
      ).and_return(results)
      expect(ldap.fetch(id)).to eq(results[0])
    end

    it 'fails if no results' do
      id = 'foo'
      results = []
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: ldap.obj_filter(id)
      ).and_return(results)
      expect { ldap.fetch(id) }.to raise_error(LdapMixin::LdapException, 'id does not exist')
    end

    it 'fails if too many results' do
      id = 'foo'
      results = [1, 2, 3]
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: ldap.obj_filter(id)
      ).and_return(results)
      expect { ldap.fetch(id) }.to raise_error(LdapMixin::LdapException, 'ambiguous results, duplicate ids')
    end
  end

  describe ':fetch_batch' do
    it 'merges IDs into an OR filter' do
      ids = ['foo', 'bar']
      expected_filter = ldap.obj_filter('foo') | ldap.obj_filter('bar')
      result = [1, 2, 3]
      expect(admin_ldap).to receive(:search).with(base: base, filter: expected_filter).and_return(result)
      expect(ldap.fetch_batch(ids)).to eq(result)
    end
  end

  describe ':fetch_by_ark' do
    it 'fetches by ARK' do
      ark = 'ark:/1234/567'
      results = [1]
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: Net::LDAP::Filter.eq('arkid', ark),
        scope: Net::LDAP::SearchScope_SingleLevel
      ).and_return(results)
      expect(ldap.fetch_by_ark_id(ark)).to eq(results[0])
    end

    it 'fails if no results' do
      ark = 'ark:/1234/567'
      results = []
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: Net::LDAP::Filter.eq('arkid', ark),
        scope: Net::LDAP::SearchScope_SingleLevel
      ).and_return(results)
      expect { ldap.fetch_by_ark_id(ark) }.to raise_error(LdapMixin::LdapException, 'id does not exist')
    end

    it 'fails if too many results' do
      ark = 'ark:/1234/567'
      results = [1, 2, 3]
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: Net::LDAP::Filter.eq('arkid', ark),
        scope: Net::LDAP::SearchScope_SingleLevel
      ).and_return(results)
      expect { ldap.fetch_by_ark_id(ark) }.to raise_error(LdapMixin::LdapException, 'ambiguous results, duplicate ids')
    end
  end

  describe ':fetch_attribute' do
    it 'fetches an attribute value' do
      id = 'foo'
      attribute = :bar
      value = 'baz'
      results = [{ attribute => value }]
      expect(admin_ldap).to receive(:search).with(
        base: base,
        filter: ldap.obj_filter(id)
      ).and_return(results)
      expect(ldap.fetch_attribute(id, attribute)).to eq(value)
    end
  end
end
