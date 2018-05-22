# ------------------------------------------------------------
# LDAP

def mock_group(group_id)
  group_ldap = {
    'ou' => [group_id],
    'submissionprofile' => ["test_profile#{group_id}"],
    'arkid' => ["ark:/99999/fk_#{group_id}"],
    'description' => "Test Group: #{group_id}"
  }

  allow(Group::LDAP).to receive(:fetch_batch).with([group_id]).and_return([group_ldap])
  allow(Group::LDAP).to receive(:fetch).with(group_id).and_return(group_ldap)

  group_ldap
end

def mock_user(user_id, password)
  user_ldap = {
    'dn' => ["uid=#{user_id},ou=People,ou=uc3,dc=cdlib,dc=org"],
    'objectclass' => ['person', 'inetOrgPerson', 'merrittUser', 'organizationalPerson', 'top'],
    'givenname' => ["J. #{user_id}"],
    'uid' => [user_id],
    'mail' => ["#{user_id}@example.edu"],
    'sn' => ['Submitter'],
    'cn' => ["J. #{user_id} Test"],
    'arkid' => ["ark:/99999/fk_#{user_id}"]
  }

  allow(User::LDAP).to receive(:authenticate).with(user_id, password).and_return(true)
  allow(User::LDAP).to receive(:fetch).with(user_id).and_return(user_ldap)

  user_ldap
end

def mock_group_permissions(user_id, group_id, permissions)
  allow(Group::LDAP).to receive(:find_groups_for_user).with(user_id, any_args).and_return([group_id])
  allow(Group::LDAP).to receive(:get_user_permissions).with(user_id, group_id, User::LDAP).and_return(permissions)
end

def mock_ldap!
  # In general, fail for unknown username / password
  allow(User::LDAP).to receive(:authenticate).and_raise(LdapMixin::LdapException)

  # ------------------------------
  # Test group

  group_01_id = 'testgroup01'
  mock_group(group_01_id)

  # ------------------------------
  # Test user

  test_user_id = 'testuser01'
  test_password = test_user_id
  mock_user(test_user_id, test_password)
  mock_group_permissions(test_user_id, group_01_id, ['read', 'write', 'download', 'admin'])

  # ------------------------------
  # Guest user

  guest_user_id = 'anonymous'
  guest_password = 'guest'
  mock_user(guest_user_id, guest_password)
  mock_group_permissions(guest_user_id, group_01_id, ['read', 'download'])
end

# ------------------------------------------------------------
# RSpec

RSpec.configure do |config|
  config.before(:each) do |_example| # mocks are only available in example context
    mock_ldap!
  end
end

