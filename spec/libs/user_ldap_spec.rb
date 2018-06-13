require 'rails_helper'

module UserLdap
  describe Server do
    attr_reader :admin_ldap
    attr_reader :user_ldap

    before(:each) do
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
      @user_ldap = User::LDAP
      @user_ldap.instance_variable_set(:@admin_ldap, nil) # make sure we get a fresh mock every time
    end

    describe ':find_all' do
      it 'filters on person and user, and sorts' do
        expected_filter = (
        Net::LDAP::Filter.eq('objectclass', 'inetOrgPerson') &
          Net::LDAP::Filter.eq('objectclass', 'merrittUser')
        )

        expect(admin_ldap).to receive(:search).with(
          base: LDAP_CONFIG["user_base"],
          filter: expected_filter,
          scope: Net::LDAP::SearchScope_SingleLevel
        ).and_return(
          [
            {'cn' => ['foo']},
            {'cn' => ['bar']},
            {'cn' => ['baz']},
          ]
        )

        expected = [
          {'cn' => ['bar']},
          {'cn' => ['baz']},
          {'cn' => ['foo']},
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
          objectclass: ["inetOrgPerson", "merrittUser"],
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
          dn: "uid=#{userid},#{LDAP_CONFIG["user_base"]}",
          attributes: expected_attribs
        ).and_return(true)

        result = user_ldap.add(userid, password, firstname, lastname, email)
        expect(result).to eq(true)
      end
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "uid=#{id},#{LDAP_CONFIG["user_base"]}"
        expect(user_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "uid" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq("uid", id)
        filter = user_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end

  end
end
