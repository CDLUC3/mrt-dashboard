require 'rails_helper'

module UserLdap
  describe Server do
    attr_reader :admin_ldap
    attr_reader :user_ldap

    before(:each) do
      unmock_ldap!

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
      @user_ldap = User::LDAP
      @user_ldap.instance_variable_set(:@admin_ldap, admin_ldap) # make sure we get a fresh mock every time
    end

    describe ':find_all' do
      it 'filters on person and user, and sorts' do
        expected_filter = (
        Net::LDAP::Filter.eq('objectclass', 'inetOrgPerson') &
          Net::LDAP::Filter.eq('objectclass', 'merrittUser')
      )

        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG['user_base'],
          filter: expected_filter,
          scope: Net::LDAP::SearchScope_SingleLevel
        ).and_return(
          [
            { 'cn' => ['foo'] },
            { 'cn' => ['bar'] },
            { 'cn' => ['baz'] }
          ]
        )

        expected = [
          { 'cn' => ['bar'] },
          { 'cn' => ['baz'] },
          { 'cn' => ['foo'] }
        ]
        actual = user_ldap.find_all
        expect(actual).to eq(expected)
      end
    end

    describe ':add' do
      it 'adds a user' do
        ark_suffix = '12345'
        allow_any_instance_of(Noid::Minter).to receive(:mint).and_return(ark_suffix)

        userid = 'elvis'
        lastname = 'Presley'
        firstname = 'Elvis'
        password = 'Trouble is going to come'
        email = 'elvis@graceland.faith'

        expected_attribs = {
          objectclass: %w[inetOrgPerson merrittUser],
          uid: userid,
          sn: lastname,
          givenName: firstname,
          cn: "#{firstname} #{lastname}",
          displayName: "#{firstname} #{lastname}",
          userPassword: password,
          arkId: "ark:/13030/#{ark_suffix}",
          mail: email
        }

        expect(admin_ldap).to receive(:add).with(
          dn: "uid=#{userid},#{LDAP_CONFIG['user_base']}",
          attributes: expected_attribs
        ).and_return(true)

        result = user_ldap.add(userid, password, firstname, lastname, email)
        expect(result).to eq(true)
      end
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "uid=#{id},#{LDAP_CONFIG['user_base']}"
        expect(user_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "uid" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq('uid', id)
        filter = user_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end

    describe ':authenticate' do
      attr_reader :user_id
      attr_reader :password

      before(:each) do
        @user_id = 'jdoe'
        @password = 'correcthorsebatterystaple'
      end

      it 'raises LdapException if ID does not exist' do
        allow(admin_ldap).to receive(:search).with(any_args).and_return([])
        expect { user_ldap.authenticate(user_id, password) }.to raise_error(LdapMixin::LdapException, 'user does not exist')
      end

      it 'succeeds if ID exists' do
        user_properties = {}
        expected_filter = user_ldap.obj_filter(user_id)
        allow(admin_ldap).to receive(:search).with(base: LDAP_CONFIG['user_base'], filter: expected_filter).and_return([user_properties])
        allow(admin_ldap).to receive(:auth).with(/#{user_id}/, password)
        allow(admin_ldap).to receive(:bind).and_return(true)
        expect(user_ldap.authenticate(user_id, password)).to eq(true)
      end
    end

    describe ':change_password' do
      it 'allows the user to change the password' do
        user_id = 'jdoe'
        new_password = 'correcthorsebatterystaple'
        expect(admin_ldap).to receive(:replace_attribute).with(/#{user_id}/, :userPassword, new_password).and_return(true)
        expect(user_ldap.change_password(user_id, new_password)).to eq(true)
      end

      it 'raises an exception if the change operation fails' do
        user_id = 'jdoe'
        new_password = 'correcthorsebatterystaple'
        expect(admin_ldap).to receive(:replace_attribute).with(/#{user_id}/, :userPassword, new_password).and_return(false)

        result = OpenStruct.new
        result.message = 'Unwilling to perform'
        expect(admin_ldap).to receive(:get_operation_result).and_return(result)
        expect { user_ldap.change_password(user_id, new_password) }.to raise_error(LdapMixin::LdapException, result.message)
      end
    end
  end
end
