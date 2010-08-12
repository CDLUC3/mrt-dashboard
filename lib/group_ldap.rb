require 'rubygems'
require 'noid'
require 'ldap_mixin'

module GroupLdap

  class Server
    include LdapMixin

    def add(groupid, description, permissions = ['read', 'write'], extra_classes = ['ezidOwnerGroup'])
      attr = {
        :objectclass           => ["organizationalUnit"] + extra_classes,
        #:name                  => groupid
        :description           => description,
        :arkId                 => @minter.mint
        }

      true_or_exception(@admin_ldap.add(:dn => ns_dn(groupid), :attributes => attr))

      permissions.each do |perm|
        attr_temp = {
          :objectclass          => ["groupOfUniqueNames"],
          :cn                   => perm
          }

        true_or_exception(@admin_ldap.add(:dn => sub_ns_dn(groupid, perm), :attributes => attr_temp))
      end

    end

    def set_user_permission(userid, groupid, user_object, permission = 'read')
      check = sub_fetch(groupid, permission)
      return true if check[:uniquemember].include?(user_object.ns_dn(userid))
      true_or_exception(@admin_ldap.add_attribute(sub_ns_dn(groupid, permission), 'uniqueMember',
            user_object.ns_dn(userid) ))
    end

    def unset_user_permission(userid, groupid, user_object, permission = 'read')
      check = sub_fetch(groupid, permission)
      return true if !check[:uniquemember].include?(user_object.ns_dn(userid))
      members = check[:uniquemember]
      members.delete(user_object.ns_dn(userid))
      @admin_ldap.replace_attribute(sub_ns_dn(groupid, permission), :uniquemember, members)
      true
    end

    def get_user_permissions(userid, groupid, user_object)
      sub_grps = @admin_ldap.search(:base => ns_dn(groupid), :filter => Net::LDAP::Filter.eq('cn','*') )
      long_user = user_object.ns_dn(userid)

      #go through subgroups for group and see if user is in each
      perms = []
      sub_grps.each do |grp|
        members = grp[:uniquemember]
        perms.push(grp[:cn][0]) if members.include?(long_user)
      end
      perms
    end

    def delete_user(userid, groupid, user_object)
      #get all cn under this ou
      sub_grps = @admin_ldap.search(:base => ns_dn(groupid), :filter => Net::LDAP::Filter.eq('cn','*') )
      long_user = user_object.ns_dn(userid)

      #go through and delete this user and replace the list of users once deleted
      sub_grps.each do |grp|
        members = grp[:uniquemember]
        members.delete_if{|member| member.eql?(long_user)}
        @admin_ldap.replace_attribute(grp[:dn], :uniquemember, members)
      end
      true
    end

    #fetches a sub object of the group organizational unit (ou)
    def sub_fetch(group_id, sub_id )
      results = @admin_ldap.search(:base => ns_dn(group_id), :filter =>
                                              Net::LDAP::Filter.eq('cn', sub_id))
      raise LdapException.new('id does not exist') if results.length < 1
      raise LdapException.new('ambigulous results, duplicate ids') if results.length > 1
      results[0]
    end

    def groups_for_user(userid)
      filter = Net::LDAP::Filter.eq("uniqueMember", namespace_dn(userid, 'people_base'))
      grps = @admin_ldap.search(:base => @groups_base, :filter => filter)
      grps.map{|grp| grp['dn'][0].gsub(@groups_base, '')[3..-2] }
    end

    def ns_dn(id)
      "ou=#{id},#{@base}"
    end

    def sub_ns_dn(id, type)
      "cn=#{type},ou=#{id},#{@base}"
    end

    def obj_filter(id)
      Net::LDAP::Filter.eq("ou", id )
    end

  end
end
