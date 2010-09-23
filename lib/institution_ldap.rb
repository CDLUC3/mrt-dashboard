require 'rubygems'
require 'noid'
require 'ldap_mixin'

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
      inst = @admin_ldap.search(:base => @base)
      inst.delete_if{|i| i['o'][0].eql?('institutions')}.sort{|x,y| x['o'][0].downcase <=> y['o'][0].downcase}
    end

  end
end

