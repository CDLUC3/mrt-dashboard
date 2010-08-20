require 'rubygems'
require 'noid'
require 'net/ldap'

module LdapCdl
  class LdapException < Exception ; end

  class Server
    attr_reader :ldap_connect, :minter
    attr_accessor :people_base, :groups_base, :admin_ldap

    #Set up this LDAP Server Connection
    def initialize(init_hash)
        
        #sample hash
        #host => "badger.cdlib.org",
        #port => 1636,
        #people_base => 'ou=People,ou=uc3,dc=cdlib,dc=org',
        #groups_base => 'ou=uc3,dc=cdlib,dc=org',
        #admin_user => 'Directory Manager',
        #admin_password => 'ahz6ap2I',
        #minter => 'http://noid.cdlib.org/nd/noidu_g9'
        
        host, port, people_base, groups_base, admin_user, admin_password, minter =
          init_hash[:host], init_hash[:port], init_hash[:people_base], init_hash[:groups_base],
          init_hash[:admin_user], init_hash[:admin_password], init_hash[:minter]

      @minter = Noid::Minter.new(minter)
      @people_base = people_base
      @groups_base = groups_base
      @ldap_connect = {:host => host, :port => port,
        :auth => {:method => :simple, :username => "cn=#{admin_user}", :password => admin_password},
        :encryption => :simple_tlsy
      }
      @admin_ldap = Net::LDAP.new(@ldap_connect)
        if !@admin_ldap.bind then
        raise LdapException.new("Unable to bind to LDAP server.")
      end
    end

    def add_user(userid, password, firstname, lastname, email, groupid, read = true, write = true)
      #probably required attributes cn (common name, first + last), displayName,  dn (distinguished name),
      #givenName (first name), sn (surname, last name), name = cn, displayName, uid,
      #userPassword, mail, title, postalAddress, initials
      attr = {
        :objectclass           => ["inetOrgPerson", 'merrittUser'],
        :uid                   => userid,
        :sn                    => lastname,
        :givenName             => firstname,
        :cn                    => "#{firstname} #{lastname}",
        :displayName           => "#{firstname} #{lastname}",
        :userPassword          => password,
        :arkId                 => @minter.mint,
        :mail                  => email
        #:mail                  => "testy@tester.com",
        #:title                 => "test user",
        #:postalAddress         => [""],
        #:initials              => "#{firstname[0,1]}#{lastname[0,1]}"
        }
      true_or_exception(@admin_ldap.add(:dn => namespace_dn(userid, 'people_base'), :attributes => attr))
      add_user_to_group(userid, groupid, read, write)
    end

    def add_group(groupid, description, extra_classes = ['merrittOwnerGroup'])

      attr = {
        :objectclass           => ["organizationalUnit"] + extra_classes,
        :name                  => groupid,
        :description           => description,
        :arkId                 => @minter.mint
        }

      true_or_exception(@admin_ldap.add(:dn => namespace_dn(groupid, 'groups_base'), :attributes => attr))

      attr_read = {
        :objectclass          => ["groupOfUniqueNames"],
        :cn                   => "read_#{groupid}"
        }

      true_or_exception(@admin_ldap.add(:dn => namespace_dn("read", 'groups_base'), :attributes => attr_read))

      attr_write = {
        :objectclass          => ["groupOfUniqueNames"],
        :cn                   => "write_#{groupid}"
        }

      true_or_exception(@admin_ldap.add(:dn => namespace_dn("write_#{groupid}", 'groups_base'), :attributes => attr_write))
      
    end

    def add_user_to_group(userid, groupid, read = true, write = true)
      if read == true then
        add_attribute("read_#{groupid}", 'uniqueMember', namespace_dn(userid, 'people_base'), 'groups_base')
      end
      if write == true then
        add_attribute("write_#{groupid}", 'uniqueMember', namespace_dn(userid, 'people_base'), 'groups_base')
      end
    end

    def delete_user(userid)
      filter = Net::LDAP::Filter.eq("uniqueMember", namespace_dn(userid, 'people_base'))
      grps = @admin_ldap.search(:base => @groups_base, :filter => filter)
      grps.each do |grp|
        grpid = grp['dn'][0].gsub(@groups_base, '')[3..-2]
        delete_attribute_value(grpid, 'uniquemember', namespace_dn(userid, 'people_base'), 'groups_base')
      end
      delete_record(userid, 'people_base')
      true
    end

    def groups_for_user(userid)
      filter = Net::LDAP::Filter.eq("uniqueMember", namespace_dn(userid, 'people_base'))
      grps = @admin_ldap.search(:base => @groups_base, :filter => filter)
      grps.map{|grp| grp['dn'][0].gsub(@groups_base, '')[3..-2] }
    end

    def delete_record(id, ns='people_base')
      raise LdapException.new('id does not exist') if !record_exists?(id)
      true_or_exception(@admin_ldap.delete(:dn => namespace_dn(id, ns)))
    end

    def authenticate(userid, password)
      raise LdapException.new('user does not exist') if !record_exists?(userid)
      ldap = Net::LDAP.new(@ldap_connect)
      ldap.auth(namespace_dn(userid, 'people_base'), password)
      ldap.bind
    end

    def change_password(userid, password)
      result = @admin_ldap.replace_attribute(namespace_dn(userid, 'people_base'), :userPassword, password)
      true_or_exception(result)
    end

    def add_attribute(id, attribute, value, ns = 'people_base')
      true_or_exception(@admin_ldap.add_attribute(namespace_dn(id, ns), attribute, value))
    end

    def replace_attribute(id, attribute, value, ns = 'people_base')
      true_or_exception(@admin_ldap.replace_attribute(namespace_dn(id, ns), attribute, value))
    end

    def delete_attribute(id, attribute, ns = 'people_base')
      true_or_exception(@admin_ldap.delete_attribute(namespace_dn(id, ns), attribute))
    end

    def delete_attribute_value(id, attribute, value, ns = 'people_base')
      attr = fetch(id, ns)[attribute]
      #true_or_exception(@admin_ldap.delete_attribute(id, attribute, ns)) #this causes an error
      attr.delete_if { |item| item == value  }
      replace_attribute(id, attribute, attr, ns)
    end

    def fetch(id, ns = 'people_base')
      filter = Net::LDAP::Filter.eq("uid", id ) if ns == 'people_base'
      filter = Net::LDAP::Filter.eq("cn", id ) if ns == 'groups_base'
      results = @admin_ldap.search(:base => self.send(ns), :filter => filter)
      raise LdapException.new('id does not exist') if results.length < 1
      raise LdapException.new('ambigulous results, duplicate ids') if results.length > 1
      results[0]
    end

    def fetch_user_and_munged_groups(userid)
      res = fetch(userid, 'people_base')
      out = {}
      res.each do |key, val|
        out[key] = val
      end
      grp_ids = groups_for_user(userid)
      grp_ids.each do |grp_id|
        grp = fetch(grp_id, 'groups_base')
        grp.each do |key, val|
          if out.has_key?("grp_#{key}") then
            out["grp_#{key}"] = out["grp_#{key}"] + val
          else
            out["grp_#{key}"] = val
          end
        end
      end
      return out
    end

    def fetch_attribute(id, attribute, ns = 'people_base')
      r = fetch(id, ns)
      raise LdapException.new('attribute does not exist for that id') if r[attribute].nil? or r[attribute].length < 1
      r[attribute]
    end

    def record_exists?(id, ns = 'people_base')
      begin
        fetch(id, ns)
      rescue LdapCdl::LdapException => ex
        return false
      end
      true
    end

#private

    def true_or_exception(result)
      if result == false then
        raise LdapException.new(@admin_ldap.get_operation_result.message)
      else
        true
      end
    end

    def namespace_dn(id, ns='people_base', sub_ns = 'read')
      if ns == 'people_base' then
        "uid=#{id},#{self.send(ns)}"
      elsif ns == 'groups_base' then
        "cn=#{sub_ns},ou=#{id},#{self.send(ns)}"
      end
    end

  end
end
