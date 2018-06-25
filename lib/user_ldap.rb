require 'rubygems'
require 'net/ldap'
#require 'lib/ldap_mixin'

module UserLdap
  class Server

    include LdapMixin



    def find_all
      return admin_ldap.search(base: @base,
                                filter: (Net::LDAP::Filter.eq('objectclass', 'inetOrgPerson') &
                                            Net::LDAP::Filter.eq('objectclass', 'merrittUser')),
                                scope: Net::LDAP::SearchScope_SingleLevel).
        sort_by{ |user| user['cn'][0].downcase }
    end

    def add(userid, password, firstname, lastname, email)
      #probably required attributes cn (common name, first + last), displayName,  dn (distinguished name),
      #givenName (first name), sn (surname, last name), name = cn, displayName, uid,
      #userPassword, mail, title, postalAddress, initials
      attr = {
        objectclass: ['inetOrgPerson', 'merrittUser'],
        uid: userid,
        sn: lastname,
        givenName: firstname,
        cn: "#{firstname} #{lastname}",
        displayName: "#{firstname} #{lastname}",
        userPassword: password,
        arkId: "ark:/13030/#{@minter.mint}",
        mail: email
        }
      true_or_exception(admin_ldap.add(dn: ns_dn(userid), attributes: attr))
    end

    def authenticate(userid, password)
      raise LdapException.new('user does not exist') if !record_exists?(userid)
      ldap = Net::LDAP.new(@ldap_connect)
      ldap.auth(ns_dn(userid), password)
      ldap.bind
    end

    def change_password(userid, password)
      result = admin_ldap.replace_attribute(ns_dn(userid), :userPassword, password)
      true_or_exception(result)
    end

    def ns_dn(id)
      "uid=#{id},#{@base}"
    end

    def obj_filter(id)
      Net::LDAP::Filter.eq('uid', id)
    end
  end
end
