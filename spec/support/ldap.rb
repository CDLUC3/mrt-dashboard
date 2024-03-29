require 'active_support/inflector'
require 'support/ark'

# ------------------------------------------------------------
# LDAP

GUEST_USER_ID = 'anonymous'.freeze
PERMISSIONS_ALL = %w[read write download admin].freeze
PERMISSIONS_READ_ONLY = %w[read download].freeze
PERMISSIONS_VIEW_ONLY = %w[read].freeze

def to_id(name)
  name.gsub(/[^A-Za-z0-9_]+/, '_').underscore
end

def to_name(user_id)
  user_id.classify.gsub(/([A-Z])/, ' \1').strip
end

def mock_collection(name:, id: nil, ark: nil)
  id ||= to_id(name)
  ark ||= ArkHelper.next_ark('collection')
  group_ldap = {
    'ou' => [id],
    'submissionprofile' => ["#{id}_profile"],
    'arkid' => [ark],
    'description' => [name]
  }
  allow(Group::LDAP).to receive(:fetch).with(id).and_return(group_ldap)
  allow(Group::LDAP).to receive(:fetch_by_ark_id).with(ark).and_return(group_ldap)
  allow(Group::LDAP).to receive(:get_user_permissions).with(anything, id, User::LDAP).and_return([])
  id
end

def mock_ldap_for_collection(inv_collection)
  mock_collection(
    name: inv_collection.name,
    id: inv_collection.mnemonic,
    ark: inv_collection.ark
  )
end

def mock_user(password:, name: nil, id: nil, tzregion: nil, telephonenumber: nil)
  raise "Can't mock without either a name or an ID" unless name || id

  id ||= to_id(name)
  name ||= to_name(id)

  names = name.scan(/[^ ]+/)
  given_name = names.first
  surname = names.last

  user_ldap = {
    'dn' => ["uid=#{id},ou=People,ou=uc3,dc=cdlib,dc=org"],
    'objectclass' => %w[person inetOrgPerson merrittUser organizationalPerson top],
    'givenname' => [given_name],
    'displayname' => [name],
    'uid' => [id],
    'mail' => ["#{id}@example.edu"],
    'sn' => [surname],
    'cn' => [name],
    'arkid' => [ArkHelper.next_ark('user')],
    'tzregion' => tzregion ? [tzregion] : [],
    'telephonenumber' => telephonenumber ? [telephonenumber] : []
  }

  allow(User::LDAP).to receive(:authenticate).with(id, password).and_return(true)
  allow(User::LDAP).to receive(:fetch).with(id).and_return(user_ldap)
  allow(Group::LDAP).to receive(:find_groups_for_user).with(id, User::LDAP, anything).and_return([])
  id
end

def mock_permissions_all(user_id, group_id_or_ids)
  gids = Array(group_id_or_ids)
  mock_permissions(user_id, gids.to_h { |gid| [gid, PERMISSIONS_ALL] })
end

def mock_permissions_read_only(user_id, group_id_or_ids)
  gids = Array(group_id_or_ids)
  mock_permissions(user_id, gids.to_h { |gid| [gid, PERMISSIONS_READ_ONLY] })
end

def mock_permissions_view_only(user_id, group_id_or_ids)
  gids = Array(group_id_or_ids)
  mock_permissions(user_id, gids.to_h { |gid| [gid, PERMISSIONS_VIEW_ONLY] })
end

def mock_permissions(user_id, perms_by_group_id)
  group_ids_by_perm = {}
  perms_by_group_id.each do |gid, perms|
    perms.each do |perm|
      group_ids_by_perm[perm] ||= []
      group_ids_by_perm[perm] << gid
    end
  end
  group_ids_by_perm.each do |perm, gids|
    allow(Group::LDAP).to receive(:find_groups_for_user).with(user_id, User::LDAP, perm).and_return(gids)
  end

  all_gids = perms_by_group_id.keys
  allow(Group::LDAP).to receive(:find_groups_for_user).with(user_id, User::LDAP, nil).and_return(all_gids)

  perms_by_group_id.each do |group_id, permissions|
    allow(Group::LDAP).to receive(:get_user_permissions).with(user_id, group_id, User::LDAP).and_return(permissions)
  end
end

def mock_ldap!
  # In general, fail for unknown username / password
  allow(User::LDAP).to receive(:authenticate).and_raise(LdapMixin::LdapException)

  # In general, fail for unknown collection
  allow(Group::LDAP).to receive(:fetch).and_raise(LdapMixin::LdapException)
  allow(Group::LDAP).to receive(:fetch_by_ark_id).and_raise(LdapMixin::LdapException)

  # Mock guest user
  mock_user(name: 'Guest User', id: GUEST_USER_ID, password: 'guest')

  # Respond to fetch_batch() for any groups mocked with mock_collection() (or otherwise mocked with :fetch)
  allow(Group::LDAP).to receive(:fetch_batch) do |group_ids|
    group_ids.map do |group_id|
      Group::LDAP.fetch(group_id)
    end
  end
end

def unmock_ldap!
  [Net::LDAP, User::LDAP, Group::LDAP, Institution::LDAP].each do |ldap|
    RSpec::Mocks.space.proxy_for(ldap).reset
  end
end

# ------------------------------------------------------------
# RSpec

RSpec.configure do |config|
  config.before(:each) do |_example| # mocks are only available in example context
    mock_ldap!
  end
end
