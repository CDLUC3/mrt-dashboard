require 'rubygems'
require 'net/ldap'
require 'noid'
require 'ldap_mixin'

module GroupLdap

  class Server
    include LdapMixin

    def find_all
      return @admin_ldap.search(:base   => @base,
                                :filter => (Net::LDAP::Filter.eq('objectclass', 'organizationalUnit') &
                                            Net::LDAP::Filter.eq('objectclass', 'merrittClass')),
                                :scope  => Net::LDAP::SearchScope_SingleLevel).
        sort_by {|g| g['ou'][0].downcase}
    end

    def find_users(grp_id)
      return @admin_ldap.search(:base   => "ou=#{grp_id},#{@base}",
                                :filter => Net::LDAP::Filter.eq('objectclass', 'groupOfUniqueNames'),
                                :scope  => Net::LDAP::SearchScope_WholeSubtree).
        map {|g| g[:uniquemember]}.
        flatten.uniq.compact.
        map {|i| i[/^uid=[^,]+/][4..-1]}
    end

    def add(groupid, description, permissions = ['read', 'write'], extra_classes = ['merrittClass'])
      attr = {
        :objectclass           => ["organizationalUnit"] + extra_classes,
        #:name                  => groupid
        :description           => description,
        :arkId                 => "ark:/13030/#{@minter.mint}"
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
    
    def find_groups_for_user(userid, user_object, permission=nil)
      #these are the permission subgroups so they need to be parsed back up a level
      filter = if permission.nil? then
                 Net::LDAP::Filter.eq("uniquemember", user_object.ns_dn(userid))
               else
                 Net::LDAP::Filter.eq("uniquemember", user_object.ns_dn(userid)) &
                   Net::LDAP::Filter.eq("cn", permission)
               end
      grps = @admin_ldap.search(:base => @base, :filter => filter)
      re = Regexp.new("^cn=(read|write|download),ou=([^, ]+),#{@base}$", Regexp::IGNORECASE)
      grps.map do |grp|
        m = re.match(grp[:dn].first)
        (!m.nil? ? m[2].to_s : nil )
      end.compact.uniq
    end

    def remove_user(userid, groupid, user_object)
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

    #fetches a cn sub object of the group organizational unit (ou)
    def sub_fetch(group_id, sub_id )
      results = @admin_ldap.search(:base => ns_dn(group_id), :filter =>
                                              Net::LDAP::Filter.eq('cn', sub_id))
      raise LdapException.new('id does not exist') if results.length < 1
      raise LdapException.new('ambiguous results, duplicate ids') if results.length > 1
      results[0]
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
