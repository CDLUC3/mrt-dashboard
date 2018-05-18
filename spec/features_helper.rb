require 'rails_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'

# ------------------------------------------------------------
# Capybara etc.

# Ideally we'd set a minimum Chromedriver version, but that's not an
# option; see https://github.com/flavorjones/chromedriver-helper
Chromedriver.set_version('2.38')

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[incognito no-sandbox disable-gpu'])
  )
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
  config.server_port = 33_000
  config.app_host = 'http://localhost:33000'
end

# ------------------------------------------------------------
# LDAP

def mock_ldap!
  allow(User::LDAP).to receive(:authenticate).and_raise(LdapMixin::LdapException)
  allow(User::LDAP).to receive(:authenticate).with("testuser01", "testuser01").and_return(true)
  allow(User::LDAP).to receive(:fetch).with("testuser01").and_return({})

  # TODO: stub this stuff in
  #
  # fetch(id) ->
  # "{:dn=>["uid=ucop_dash_submitter,ou=People,ou=uc3,dc=cdlib,dc=org"], :objectclass=>["person", "inetOrgPerson", "merrittUser", "organizationalPerson", "top"], :givenname=>["UCOP Dash"], :uid=>["ucop_dash_submitter"], :mail=>["uc3@ucop.edu"], :sn=>["Submitter"], :userpassword=>["{SSHA}UWBCYXx6gGorIF+QbypAFAehYEmbBmDn9bqwug=="], :cn=>["UCOP Dash Submitter"], :arkid=>["ark:/99166/p9z60c34s"]}"
  #
  # Group::LDAP.find_groups_for_user ->
  # ["dash_cdl"]
  #
  # current_user.groups -> (array of:)
  # "#<Group:0x007f95968c3a60 @id="dash_cdl", @submission_profile="dash_cdl_content", @ark_id="ark:/99999/fk4pg1qtb", @owner=nil, @description="DASH CDL collection">"
  #
  # group.permission('ucop_dash_submitter') -> Array<Net::BER::BERIdentifiedString>
  # "["read", "write", "download", "admin"]"

  allow(Group::LDAP).to receive(:find_groups_for_user) do |userid, user_object, permission=nil|
  end
end

RSpec.configure do |config|
  config.before(:each) do |_example| # mocks are only available in example context
    mock_ldap!
  end
end

# ------------------------------------------------------------
# Capybara helpers

def log_in!
  visit login_path
  fill_in "login", :with => "testuser01"
  fill_in "password", :with => "testuser01"
  click_button "Login"
end
