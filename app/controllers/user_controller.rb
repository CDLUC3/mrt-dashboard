class UserController < ApplicationController
  before_action :require_user

  REQUIRED = {
    'givenname' => 'First name',
    'sn' => 'Last name',
    'userpassword' => 'Password',
    'repeatuserpassword' => 'Repeat Password',
    'mail' => 'Email'
  }.freeze

  PASSWORD_MISMATCH_MSG = 'Your password and repeated password do not match.'.freeze
  PROFILE_UPDATED_MSG = 'Your profile has been updated.'.freeze

  def update
    @ldap_user = User::LDAP.fetch(current_user.login) # uncached from LDAP, so always current
    if params[:givenname]
      @missing_params = find_missing(params)
      cache_field_values(params)
      do_update!
    else
      @display_text = '' # TODO: why?
    end
  end

  private

  def do_update!
    if @missing_params.any?
      missing_param_list = @missing_params.map { |i| REQUIRED[i] }.join(', ')
      @display_text = "The following items must be filled in: #{missing_param_list}."
    elsif password_mismatch?(params)
      @display_text = PASSWORD_MISMATCH_MSG
    else
      replace_attributes!(params)
      @display_text = PROFILE_UPDATED_MSG
    end
  end

  def replace_attributes!(params)
    attributes_from(params).each do |attrib, value|
      User::LDAP.replace_attribute(current_user.login, attrib, value)
    end
  end

  def cache_field_values(params)
    params.each_pair { |k, v| @ldap_user[k] = v }
  end

  def find_missing(params)
    REQUIRED.keys.select { |key| params[key].blank? }
  end

  def password_mismatch?(params)
    params[:userpassword] != params[:repeatuserpassword]
  end

  def attributes_from(params)
    # Basic attributes
    attributes = %w[givenname sn mail tzregion telephonenumber].to_h { |k| [k, params[k]] }

    # Password
    userpassword = params['userpassword']
    attributes['userpassword'] = userpassword unless userpassword == '!unchanged'

    # Telephone number
    telephonenumber = params['telephonenumber']
    attributes['telephonenumber'] = telephonenumber unless telephonenumber.blank?

    # Full name
    %w[cn displayname].each { |attrib| attributes[attrib] = "#{params['givenname']} #{params['sn']}" }

    # Return value
    attributes
  end
end
