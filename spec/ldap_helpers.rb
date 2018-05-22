require 'active_support/inflector'

# ------------------------------------------------------------
# LDAP

GUEST_USER_ID = 'anonymous'
PERMISSIONS_ALL = ['read', 'write', 'download', 'admin'].freeze
PERMISSIONS_READ_ONLY = ['read', 'download'].freeze

def to_id(name)
  name.gsub(/[^A-Za-z0-9_]+/, '_').underscore
end

def to_name(user_id)
  user_id.classify.gsub(/([A-Z])/, ' \1').strip
end

def mock_collection(collection_name)
  group_id = to_id(collection_name)
  group_ldap = {
    'ou' => [group_id],
    'submissionprofile' => ["#{group_id}_profile"],
    'arkid' => ["ark:/99999/fk_#{group_id}"],
    'description' => [collection_name]
  }
  allow(Group::LDAP).to receive(:fetch).with(group_id).and_return(group_ldap)
  group_id
end

def mock_user(name: nil, id: nil, password: nil)
  raise "Can't mock without either a name or an ID" unless (name || id)

  id ||= to_id(name)
  name ||= to_name(id)
  password ||= "password for #{id}"

  given_name = name.scan(/[^ ]+/).first
  user_ldap = {
    'dn' => ["uid=#{id},ou=People,ou=uc3,dc=cdlib,dc=org"],
    'objectclass' => ['person', 'inetOrgPerson', 'merrittUser', 'organizationalPerson', 'top'],
    'givenname' => [given_name],
    'uid' => [id],
    'mail' => ["#{id}@example.edu"],
    'sn' => ['User'],
    'cn' => [name],
    'arkid' => ["ark:/99999/fk_#{id}"]
  }

  allow(User::LDAP).to receive(:authenticate).with(id, password).and_return(true)
  allow(User::LDAP).to receive(:fetch).with(id).and_return(user_ldap)

  id
end

def mock_permissions(user_id, perms_by_group_id)
  group_ids = perms_by_group_id.keys
  allow(Group::LDAP).to receive(:find_groups_for_user).with(user_id, any_args).and_return(group_ids)
  perms_by_group_id.each do |group_id, permissions|
    allow(Group::LDAP).to receive(:get_user_permissions).with(user_id, group_id, User::LDAP).and_return(permissions)
  end
end

def mock_ldap!
  # In general, fail for unknown username / password
  allow(User::LDAP).to receive(:authenticate).and_raise(LdapMixin::LdapException)

  # Mock guest user
  mock_user(name: 'Guest User', id: GUEST_USER_ID, password: 'guest')

  # Respond to fetch_batch() for any groups mocked with mock_collection() (or otherwise mocked with :fetch)
  allow(Group::LDAP).to receive(:fetch_batch) do |group_ids|
    group_ids.map do |group_id|
      Group::LDAP.fetch(group_id)
    end
  end
end

# ------------------------------------------------------------
# RSpec

RSpec.configure do |config|
  config.before(:each) do |_example| # mocks are only available in example context
    mock_ldap!
  end
end

