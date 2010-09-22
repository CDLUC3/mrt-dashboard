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

    def institutions
      #these are the permission subgroups so they need to be parsed back up a level
      inst = @admin_ldap.search(:base => @base)
      inst.map{|i| i[:o][0]}.delete_if{|i| i.eql?('institutions')}.sort{|x,y| x.downcase <=> y.downcase}
    end

  end
end

