class UserController < ApplicationController
  before_filter :require_user

  REQUIRED = {
    'givenname'          => 'First name',
    'sn'                 => 'Last name',
    'userpassword'       => 'Password',
    'repeatuserpassword' => 'Repeat Password',
    'mail'               => 'Email'
  }.freeze

  def update
    # uncached from LDAP, so always current
    @ldap_user = User::LDAP.fetch(current_user.login)

    @display_text = ''
    return if params[:givenname].nil?

    # put updated info in this hash so they don't have to retype
    params.each_pair { |k, v| @ldap_user[k] = v }
    error_fields = REQUIRED.keys.select { |key| params[key].blank? }
    if !error_fields.empty?
      @display_text += 'The following items must be filled in: '
      @display_text += error_fields.map { |i| REQUIRED[i] }.join(', ')
      @display_text += '.'
    elsif params[:userpassword] != params[:repeatuserpassword]
      @display_text += 'Your password and repeated password do not match.'
    else
      params[:telephonenumber] = nil if params[:telephonenumber] == ''

      %w[givenname sn mail tzregion telephonenumber].each do |i|
        User::LDAP.replace_attribute(current_user.login, i, params[i])
      end
      %w[cn displayname].each do |i|
        User::LDAP.replace_attribute(current_user.login, i, "#{params['givenname']} #{params['sn']}")
      end
      User::LDAP.replace_attribute(current_user.login, 'userpassword', params['userpassword']) if params['userpassword'] != '!unchanged'
      @display_text = 'Your profile has been updated.'
    end
  end
end
