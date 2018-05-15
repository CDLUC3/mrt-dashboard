module InstitutionLdap
  class Server
    include LdapMixin

    def ns_dn(id)
      "o=#{id},#{@base}"
    end

    def obj_filter(id)
      Net::LDAP::Filter.eq("o", id )
    end

    def find_all
      return admin_ldap.search(:base => @base).
        reject{ |i| i['o'][0] == 'institutions' }.
        sort_by{ |i| i['o'][0].downcase }
    end
  end
end
