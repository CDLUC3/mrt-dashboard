# mix this in to the user and group ldap modules for common functionality
# mixed in modules must define ns_dn(id) and obj_filter(id) methods which differ
# for each (like a Java abstract class) as well as any specific methods for each

# require 'lib/noid'

module LdapMixin

  class LdapException < Exception; end

  attr_reader :ldap_connect, :minter
  attr_accessor :base


  def initialize(init_hash)

    # sample hash
    # host => "badger.cdlib.org",
    # port => 1636,
    # base => 'ou=People,ou=uc3,dc=cdlib,dc=org',
    # admin_user => 'Directory Manager',
    # admin_password => 'XXXXXXX',
    # minter => 'http://noid.cdlib.org/nd/noidu_g9'
    # connect_timeout => 60

    host, port, base, admin_user, admin_password, minter, connect_timeout =
      init_hash[:host], init_hash[:port], init_hash[:base],
      init_hash[:admin_user], init_hash[:admin_password],
      init_hash[:minter], init_hash[:connect_timeout]

    @minter = Noid::Minter.new(minter)
    @base = base
    @ldap_connect = {
      host: host,
      port: port,
      auth: { method: :simple, username: admin_user, password: admin_password },
      encryption: {
        method: :simple_tls,
        tls_options: { ssl_version: 'TLSv1_1' }
      },
      connect_timeout: connect_timeout
    }

    unless ENV['RAILS_ENV'] == 'test' || admin_ldap.bind
      raise LdapException.new('Unable to bind to LDAP server.')
    end
  end

  def admin_ldap
    @admin_ldap ||= begin
      Net::LDAP.new(@ldap_connect)
    end
  end

  def delete_record(id)
    raise LdapException.new('id does not exist') if !record_exists?(id)
    true_or_exception(admin_ldap.delete(dn: ns_dn(id)))
  end

  def add_attribute(id, attribute, value)
    # @admin_ldap.add_attribute(ns_dn(id), attribute, value)
    true_or_exception(admin_ldap.add_attribute(ns_dn(id), attribute, value))
  end

  def replace_attribute(id, attribute, value)
    true_or_exception(admin_ldap.replace_attribute(ns_dn(id), attribute, value))
  end

  def delete_attribute(id, attribute)
    true_or_exception(admin_ldap.delete_attribute(ns_dn(id), attribute))
  end

  def delete_attribute_value(id, attribute, value)
    attr = fetch(id)[attribute]
    # true_or_exception(@admin_ldap.delete_attribute(id, attribute)) #this causes an error
    attr.delete_if { |item| item == value  }
    replace_attribute(id, attribute, attr) # TODO: should we bother if no change?
  end

  # returns in unspecified order
  def fetch_batch(ids)
    # ids must be complete CNs
    filter = nil
    ids.each do |id|
      if filter.nil? then
        filter = obj_filter(id)
      else
        filter = filter | obj_filter(id)
      end
    end
    admin_ldap.search(base: @base, filter: filter)
  end

  def fetch(id)
    results = admin_ldap.search(base: @base, filter: obj_filter(id))
    raise LdapException.new('id does not exist') if results.length < 1
    raise LdapException.new('ambiguous results, duplicate ids') if results.length > 1
    results[0]
  end

  def fetch_by_ark_id(ark_id)
    results = admin_ldap.search(base: @base,
                                filter: Net::LDAP::Filter.eq('arkid', ark_id),
                                scope: Net::LDAP::SearchScope_SingleLevel)
    raise LdapException.new('id does not exist') if results.length < 1
    raise LdapException.new('ambiguous results, duplicate ids') if results.length > 1
    results[0]
  end

  def fetch_attribute(id, attribute)
    r = fetch(id)
    raise LdapException.new('attribute does not exist for that id') if r[attribute].nil? or r[attribute].length < 1
    r[attribute]
  end

  def record_exists?(id)
    begin
      fetch(id)
    rescue LdapMixin::LdapException => ex
      return false
    end
    true
  end

  def true_or_exception(result)
    if result == false then
      raise LdapException.new(admin_ldap.get_operation_result.message)
    else
      true
    end
  end
end
