require 'rails_helper'

module GroupLdap
  describe Server do
    attr_reader :admin_ldap
    attr_reader :group_ldap
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

      @group_ldap = Group::LDAP
      @group_ldap.instance_variable_set(:@admin_ldap, admin_ldap) # make sure we get a fresh mock every time

      @user_ldap = User::LDAP
      @user_ldap.instance_variable_set(:@admin_ldap, admin_ldap) # make sure we get a fresh mock every time
    end

    describe ':find_all' do
      it 'filters on org and class, and sorts' do
        expected_filter = (
        Net::LDAP::Filter.eq('objectclass', 'organizationalUnit') &
          Net::LDAP::Filter.eq('objectclass', 'merrittClass')
        )

        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG['group_base'],
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

    describe ':find_users' do
      it 'filters on unique members and parses out IDs' do
        group_id = 'qux'
        expected_filter = Net::LDAP::Filter.eq('objectclass', 'groupOfUniqueNames')
        expected_base = "ou=#{group_id},#{LDAP_CONFIG['group_base']}"

        expect(admin_ldap).to receive(:search).with(
          base: expected_base,
          filter: expected_filter,
          scope: Net::LDAP::SearchScope_WholeSubtree
        ).and_return(
          [
            { uniquemember: ['uid=foo', 'uid=bar'] },
            { uniquemember: ['uid=foo', 'uid=baz'] },
          ]
        )

        expect(group_ldap.find_users(group_id)).to eq(['foo', 'bar', 'baz'])
      end
    end

    describe ':add' do
      it 'adds a group' do
        ark_suffix = '12345'
        allow_any_instance_of(Noid::Minter).to receive(:mint).and_return(ark_suffix)

        group_id = 'foo'
        description = 'bar'
        expected_attribs = {
          objectclass: ['organizationalUnit', 'merrittClass'],
          description: description,
          arkId: "ark:/13030/#{ark_suffix}"
        }

        expect(admin_ldap).to receive(:add).with(
          dn: group_ldap.ns_dn(group_id),
          attributes: expected_attribs
        ).and_return(true)

        ['read', 'write'].each do |perm|
          expect(admin_ldap).to receive(:add).with(
            dn: group_ldap.sub_ns_dn(group_id, perm),
            attributes: { objectclass: ['groupOfUniqueNames'], cn: perm }
          ).and_return(true)
        end

        group_ldap.add(group_id, description)
      end
    end

    describe ':sub_fetch' do
      it 'fetches a subgroup' do
        group_id = 'foo'
        sub_id = 'bar'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', sub_id)
        ).and_return(results)

        expect(group_ldap.sub_fetch(group_id, sub_id)).to eq(results[0])
      end
    end

    describe ':set_user_permission' do
      it 'sets the permission' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'write'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).to receive(:add_attribute).with(
          group_ldap.sub_ns_dn(group_id, permission), 'uniqueMember', user_ldap.ns_dn(user_id)
        ).and_return(true)

        group_ldap.set_user_permission(user_id, group_id, user_ldap, permission)
      end

      it 'skips users who already have the permission' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'write'

        results = [
          {
            dn: 'wibble',
            uniquemember: [user_id, 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).not_to receive(:add_attribute)

        group_ldap.set_user_permission(user_id, group_id, user_ldap, permission)
      end

      it 'defaults to read' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'read'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).to receive(:add_attribute).with(
          group_ldap.sub_ns_dn(group_id, permission), 'uniqueMember', user_ldap.ns_dn(user_id)
        ).and_return(true)

        group_ldap.set_user_permission(user_id, group_id, user_ldap)
      end
    end

    describe ':unset_user_permissions' do
      it 'skips users who already don\'t have the permission' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'write'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).not_to receive(:replace_attribute)

        group_ldap.unset_user_permission(user_id, group_id, user_ldap, permission)
      end

      it 'removes the specified permission' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'write'

        results = [
          {
            dn: 'wibble',
            uniquemember: [user_id, 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).to receive(:replace_attribute).with(
          group_ldap.sub_ns_dn(group_id, permission), :uniquemember, ['qux'].map { |uid| user_ldap.ns_dn(uid) }
        )

        group_ldap.unset_user_permission(user_id, group_id, user_ldap, permission)
      end

      it 'defaults to "read"' do
        group_id = 'foo'
        user_id = 'bar'
        permission = 'read'

        results = [
          {
            dn: 'wibble',
            uniquemember: [user_id, 'qux'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', permission)
        ).and_return(results)

        expect(admin_ldap).to receive(:replace_attribute).with(
          group_ldap.sub_ns_dn(group_id, permission), :uniquemember, ['qux'].map { |uid| user_ldap.ns_dn(uid) }
        )

        group_ldap.unset_user_permission(user_id, group_id, user_ldap)
      end
    end

    describe ':get_user_permissions' do
      it 'gets the user permissions' do
        user_id = 'foo'
        group_id = 'bar'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', user_id].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          },
          {
            dn: 'flob',
            uniquemember: ['corge', 'grault'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['garply']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id), filter: Net::LDAP::Filter.eq('cn','*')
        ).and_return(results)

        expect(group_ldap.get_user_permissions(user_id, group_id, user_ldap)).to eq(['quux'])
      end
    end

    describe ':remove_user' do
      it 'removes a user' do

        user_id = 'qux'
        group_id = 'foo'

        results = [
          {
            dn: 'wibble',
            uniquemember: ['baz', user_id].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['quux']
          },
          {
            dn: 'flob',
            uniquemember: ['corge', 'grault'].map { |uid| user_ldap.ns_dn(uid) },
            cn: ['garply']
          }
        ]

        expect(admin_ldap).to receive(:search).with(
          base: group_ldap.ns_dn(group_id),
          filter: Net::LDAP::Filter.eq('cn', '*')
        ).and_return(results)

        expect(admin_ldap).to receive(:replace_attribute).with(
          'wibble', :uniquemember, ['baz'].map { |uid| user_ldap.ns_dn(uid) }
        )

        expect(admin_ldap).to receive(:replace_attribute).with(
          'flob', :uniquemember, ['corge', 'grault'].map { |uid| user_ldap.ns_dn(uid) }
        )

        group_ldap.remove_user(user_id, group_id, user_ldap)
      end
    end

    describe ':find_groups_for_user' do
      attr_reader :user_id

      before(:each) do
        @user_id = 'grault'
      end

      it 'finds users without specified permissions' do
        expected_filter = Net::LDAP::Filter.eq('uniquemember', user_ldap.ns_dn(user_id))
        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG['group_base'], filter: expected_filter
        ).and_return([
          { dn: [group_ldap.sub_ns_dn('foo', 'bar')] },
          { dn: [group_ldap.sub_ns_dn('bar', 'read')] },
          { dn: [group_ldap.sub_ns_dn('baz', 'write')] },
          { dn: [group_ldap.sub_ns_dn('qux', 'download')] },
          { dn: [group_ldap.sub_ns_dn('quux', 'corge')] },
        ])

        expect(group_ldap.find_groups_for_user(user_id, user_ldap)).to eq(['bar', 'baz', 'qux'])
      end

      it 'finds users with specified permissions' do
        perm = 'garply'
        expected_filter = (
        Net::LDAP::Filter.eq('uniquemember', user_ldap.ns_dn(user_id)) &
          Net::LDAP::Filter.eq('cn', perm)
        )

        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG['group_base'], filter: expected_filter
        ).and_return([
          # note that the LDAP filter uses the passed permission, but the find method
          # itself only checks the LDAP results for cn=(read|write|download)
          { dn: [group_ldap.sub_ns_dn('foo', 'bar')] },
          { dn: [group_ldap.sub_ns_dn('bar', 'read')] },
          { dn: [group_ldap.sub_ns_dn('baz', 'write')] },
          { dn: [group_ldap.sub_ns_dn('qux', 'download')] },
          { dn: [group_ldap.sub_ns_dn('quux', 'corge')] },
        ])

        expect(group_ldap.find_groups_for_user(user_id, user_ldap, perm)).to eq(['bar', 'baz', 'qux'])
      end
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "ou=#{id},#{LDAP_CONFIG['group_base']}"
        expect(group_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':sub_ns_dn' do
      it 'wraps the ID and type and appends the base' do
        id = 'foo'
        type = 'bar'
        expected = "cn=#{type},ou=#{id},#{LDAP_CONFIG['group_base']}"
        expect(group_ldap.sub_ns_dn(id, type)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "ou" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq('ou', id)
        filter = group_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end
  end
end
