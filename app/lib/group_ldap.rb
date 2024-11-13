require 'rubygems'
require 'net/ldap'
# require 'ldap_mixin'

module GroupLdap

  class Server
    include LdapMixin

    def find_all
      results = admin_ldap.search(
        base: @base,
        filter: (Net::LDAP::Filter.eq('objectclass', 'organizationalUnit') &
          Net::LDAP::Filter.eq('objectclass', 'merrittClass')),
        scope: Net::LDAP::SearchScope_SingleLevel
      )
      results.sort_by { |g| g['ou'][0].downcase }
    end

    def find_users(grp_id)
      results = admin_ldap.search(
        base: "ou=#{grp_id},#{@base}",
        filter: Net::LDAP::Filter.eq('objectclass', 'groupOfUniqueNames'),
        scope: Net::LDAP::SearchScope_WholeSubtree
      )
      results
        .map { |g| g[:uniquemember] }
        .flatten.uniq.compact
        .map { |i| i[/^uid=[^,]+/][4..] }
    end

    def add(groupid, description, permissions = %w[read write], extra_classes = ['merrittClass'])
      group_attributes = {
        objectclass: ['organizationalUnit'] + extra_classes,
        description: description,
        arkId: 'ark:/13030/12345'
      }
      true_or_exception(admin_ldap.add(dn: ns_dn(groupid), attributes: group_attributes))

      permissions.each do |perm|
        perm_attributes = { objectclass: ['groupOfUniqueNames'], cn: perm }
        true_or_exception(admin_ldap.add(dn: sub_ns_dn(groupid, perm), attributes: perm_attributes))
      end
    end

    def set_user_permission(userid, groupid, user_ldap, permission = 'read')
      user_ns_dn = user_ldap.ns_dn(userid)
      check = sub_fetch(groupid, permission)
      return true if check[:uniquemember].include?(user_ns_dn)

      true_or_exception(admin_ldap.add_attribute(sub_ns_dn(groupid, permission), 'uniqueMember', user_ns_dn))
    end

    def unset_user_permission(userid, groupid, user_ldap, permission = 'read')
      user_ns_dn = user_ldap.ns_dn(userid)
      check = sub_fetch(groupid, permission)
      return true unless check[:uniquemember].include?(user_ns_dn)

      members = check[:uniquemember]
      members.delete(user_ns_dn)
      admin_ldap.replace_attribute(sub_ns_dn(groupid, permission), :uniquemember, members)
      true
    end

    def get_user_permissions(userid, groupid, user_ldap)
      sub_grps = admin_ldap.search(base: ns_dn(groupid), filter: Net::LDAP::Filter.eq('cn', '*'))
      user_ns_dn = user_ldap.ns_dn(userid)
      perms = []
      sub_grps.each { |grp| perms.push(grp[:cn][0]) if grp[:uniquemember].include?(user_ns_dn) }
      perms
    end

    def find_groups_for_user(userid, user_ldap, permission = nil)
      user_ns_dn = user_ldap.ns_dn(userid)
      groups = admin_ldap.search(base: @base, filter: unique_member_filter(user_ns_dn, permission))
      pattern = Regexp.new("^cn=(read|write|download),ou=([^, ]+),#{@base}$", Regexp::IGNORECASE)
      groups.map do |grp|
        m = pattern.match(grp[:dn].first)
        m[2].to_s if m
      end.compact.uniq
    end

    def remove_user(userid, groupid, user_ldap)
      sub_grps = admin_ldap.search(base: ns_dn(groupid), filter: Net::LDAP::Filter.eq('cn', '*'))
      user_ns_dn = user_ldap.ns_dn(userid)

      # go through and delete this user and replace the list of users once deleted
      sub_grps.each do |grp|
        # TODO: is the user always present? if not, we're replacing when we don't need to
        members = grp[:uniquemember]
        members.delete_if { |member| member.eql?(user_ns_dn) }
        admin_ldap.replace_attribute(grp[:dn], :uniquemember, members)
      end

      true
    end

    # fetches a cn sub object of the group organizational unit (ou)
    def sub_fetch(group_id, sub_id)
      results = admin_ldap.search(base: ns_dn(group_id), filter: Net::LDAP::Filter.eq('cn', sub_id))
      raise LdapException, 'id does not exist' if results.empty?
      raise LdapException, 'ambiguous results, duplicate ids' if results.length > 1

      results[0]
    end

    def ns_dn(id)
      "ou=#{id},#{@base}"
    end

    def sub_ns_dn(id, type)
      "cn=#{type},ou=#{id},#{@base}"
    end

    def obj_filter(id)
      Net::LDAP::Filter.eq('ou', id)
    end

    private

    def unique_member_filter(user_ns_dn, permission)
      filter = Net::LDAP::Filter.eq('uniquemember', user_ns_dn)
      filter &= Net::LDAP::Filter.eq('cn', permission) if permission
      filter
    end

  end
end
