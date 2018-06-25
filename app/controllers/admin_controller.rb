class AdminController < ApplicationController
  before_filter :require_user

  # :nocov:
  def create_user
    @ldap_user = { 'tzregion' => 'America/Los_Angeles' }
    @error_fields = []
    @display_text = ''
    unless params[:givenname].nil?
      params.each_pair { |k, v| @ldap_user[k] = v } # stuck updated info in this hash so they don't have to retype
      @required = { 'givenname' => 'First name', 'sn' => 'Last name', 'uid' => 'User Id',
                    'userpassword' => 'Password', 'repeatuserpassword' => 'Repeat Password',
                    'mail' => 'Email' }
      @required.each_key do |key|
        @error_fields.push(key) if params[key].blank?
      end
      if @error_fields.length > 0 or !params[:userpassword].eql?(params[:repeatuserpassword])
        @display_text += "The following items must be filled in: #{@error_fields.map { |i| @required[i] }.join(', ')}." if @error_fields.length > 0
        @display_text += ' Your password and repeated password do not match.' unless params[:userpassword].eql?(params[:repeatuserpassword])
      else
        User::LDAP.add(params[:uid], params[:userpassword], params[:givenname],
                       params[:sn], params[:mail])
        %w[tzregion telephonenumber institution].each do |i|
          User::LDAP.replace_attribute(params[:uid], i, params[i])
        end
        @display_text = 'This user profile has been created.'
        @ldap_user = User::LDAP.fetch(params[:uid])
      end
    end
  end
  # :nocov:

  # :nocov:
  def create_group
    @ldap_group = {}
    @error_fields = []
    @display_text = ''
    unless params[:ou].nil?
      params.each_pair { |k, v| @ldap_group[k] = v } # stuck updated info in this hash so they don't have to retype
      @required = { 'ou' => 'collection ID', 'description' => 'description',
                    'submissionprofile' => 'Ingest Profile ID' }
      @required.each_key do |key|
        @error_fields.push(key) if params[key].blank?
      end
      if @error_fields.length > 0
        @display_text += "The following items must be filled in: #{@error_fields.map { |i| @required[i] }.join(', ')}."
      else
        Group::LDAP.add(params[:ou], params[:description], %w[read write], ['merrittClass'])
        Group::LDAP.replace_attribute(params[:ou], 'submissionprofile', params['submissionprofile'])
        @display_text = 'This collection has been created.'
        @ldap_group = Group::LDAP.fetch(params[:ou])
      end
    end
  end
  # :nocov:

  # :nocov:
  def add_user_to_group
    @ldap = {}
    @m_grps = Group.find_all.map { |i| [i['description'][0], i['ou'][0]] }
    @m_usrs = User.find_all.map { |i| [i['cn'][0], i['uid'][0]] }
    @perms = []

    if params[:submitted].eql?('true')
      @ldap[:uid] = params[:uid]
      @ldap[:ou] = params[:ou]

      %w[read write].each do |perm|
        if params[:permissions].nil? or !params[:permissions].include?(perm)
          Group::LDAP.unset_user_permission(params[:uid], params[:ou], User::LDAP, perm)
        else
          Group::LDAP.set_user_permission(params[:uid], params[:ou], User::LDAP, perm)
        end
      end
      # get permissions from LDAP
      usr = User::LDAP.fetch(params[:uid])
      grp = Group.find(params[:ou])
      @perms = grp.permission(params[:uid])
      @display_text = 'The user permissions were set as shown below.  The user is likely to need ' +
       "their email address (#{usr[:mail][0]}) added or removed from the ingest profile (#{grp.submission_profile}) in the ingest service." +
       ' If it is not modified they may not receive appropriate emails from the ingest service.'
    else
      # nothing checked
    end
  end
  # :nocov:
end
