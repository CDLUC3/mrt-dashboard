require 'rails_helper'

module InstitutionLdap
  describe Server do
    attr_reader :admin_ldap
    attr_reader :inst_ldap

    before(:each) do
      unmock_ldap!

      ldap_params = {
        :host => LDAP_CONFIG['host'],
        :port => LDAP_CONFIG['port'],
        :auth => {
          :method => :simple,
          :username => LDAP_CONFIG['admin_user'],
          :password => LDAP_CONFIG['admin_password']
        },
        :encryption => {
          :method => :simple_tls,
          :tls_options => {
            :ssl_version => 'TLSv1_1'
          }
        },
        :connect_timeout => LDAP_CONFIG['connect_timeout']
      }

      @admin_ldap = double(Net::LDAP)
      allow(Net::LDAP).to receive(:new).with(ldap_params).and_return(admin_ldap)

      @inst_ldap = Institution::LDAP
      @inst_ldap.instance_variable_set(:@admin_ldap, nil) # make sure we get a fresh mock every time
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "o=#{id},#{LDAP_CONFIG["inst_base"]}"
        expect(inst_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "o" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq('o', id)
        filter = inst_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end

    describe ':find_all' do
      it 'filters out institutions' do # TODO: can't be right, must be misunderstanding what it's doing
        result = [
          { 'o' => ['institutions'] },
          { 'o' => ['foo'] },
          { 'o' => ['bar'] },
          { 'o' => ['institutions'] },
        ]
        expect(admin_ldap).to receive(:search).with(base: LDAP_CONFIG['inst_base']).and_return(result)

        expected = [
          { 'o' => ['bar'] },
          { 'o' => ['foo'] },
        ]
        expect(inst_ldap.find_all).to eq(expected)
      end
    end

  end
end
