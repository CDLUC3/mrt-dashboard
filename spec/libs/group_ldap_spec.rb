require 'rails_helper'

module GroupLdap
  describe Server do
    attr_reader :admin_ldap
    attr_reader :group_ldap

    before(:each) do
      unmock_ldap!

      ldap_params = {
        :host => LDAP_CONFIG["host"],
        :port => LDAP_CONFIG["port"],
        :auth => {
          :method => :simple,
          :username => LDAP_CONFIG["admin_user"],
          :password => LDAP_CONFIG["admin_password"]
        },
        :encryption => {
          :method => :simple_tls,
          :tls_options => {
            :ssl_version => "TLSv1_1"
          }
        },
        :connect_timeout => LDAP_CONFIG["connect_timeout"]
      }

      @admin_ldap = double(Net::LDAP)
      allow(Net::LDAP).to receive(:new).with(ldap_params).and_return(admin_ldap)

      @group_ldap = Group::LDAP
      @group_ldap.instance_variable_set(:@admin_ldap, admin_ldap) # make sure we get a fresh mock every time
    end

    describe ':find_all' do
      it 'filters on org and class, and sorts' do
        expected_filter = (
        Net::LDAP::Filter.eq('objectclass', 'organizationalUnit') &
          Net::LDAP::Filter.eq('objectclass', 'merrittClass')
        )
        
        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG["group_base"],
          filter: expected_filter,
          scope: Net::LDAP::SearchScope_SingleLevel
        ).and_return(
          [
            { 'ou' => ['foo'] },
            { 'ou' => ['bar'] },
            { 'ou' => ['baz'] },
          ]
        )

        expected = [
          { 'ou' => ['bar'] },
          { 'ou' => ['baz'] },
          { 'ou' => ['foo'] },
        ]
        actual = group_ldap.find_all
        expect(actual).to eq(expected)
      end
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "ou=#{id},#{LDAP_CONFIG["group_base"]}"
        expect(group_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':sub_ns_dn' do
      it 'wraps the ID and type and appends the base' do
        id = 'foo'
        type = 'bar'
        expected = "cn=#{type},ou=#{id},#{LDAP_CONFIG["group_base"]}"
        expect(group_ldap.sub_ns_dn(id, type)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "ou" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq("ou", id)
        filter = group_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end
  end
end
