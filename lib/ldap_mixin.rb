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

    host = init_hash[:host]
    port = init_hash[:port]
    base = init_hash[:base]
    admin_user = init_hash[:admin_user]
    admin_password = init_hash[:admin_password]
    minter = init_hash[:minter]
    connect_timeout = init_hash[:connect_timeout]

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

    raise LdapException, 'Unable to bind to LDAP server.' unless ENV['RAILS_ENV'] == 'test' || admin_ldap.bind
  end

  def admin_ldap
    @admin_ldap ||= begin
      Net::LDAP.new(@ldap_connect)
    end
  end

  def delete_record(id)
    raise LdapException, 'id does not exist' unless record_exists?(id)
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
      filter = if filter.nil?
                 obj_filter(id)
               else
                 filter | obj_filter(id)
               end
    end
    admin_ldap.search(base: @base, filter: filter)
  end

  def fetch(id)
    results = admin_ldap.search(base: @base, filter: obj_filter(id))
    raise LdapException, 'id does not exist' if results.empty?
    raise LdapException, 'ambiguous results, duplicate ids' if results.length > 1
    results[0]
  end

  def fetch_by_ark_id(ark_id)
    results = admin_ldap.search(base: @base,
                                filter: Net::LDAP::Filter.eq('arkid', ark_id),
                                scope: Net::LDAP::SearchScope_SingleLevel)
    raise LdapException, 'id does not exist' if results.empty?
    raise LdapException, 'ambiguous results, duplicate ids' if results.length > 1
    results[0]
  end

  def fetch_attribute(id, attribute)
    r = fetch(id)
    raise LdapException, 'attribute does not exist for that id' if r[attribute].nil? || r[attribute].empty?
    r[attribute]
  end

  def record_exists?(id)
    
      fetch(id)
      true
    rescue LdapMixin::LdapException => ex
      return false
    
  end

  def true_or_exception(result)
    return true if result
    raise LdapException, admin_ldap.get_operation_result.message
  end
end
