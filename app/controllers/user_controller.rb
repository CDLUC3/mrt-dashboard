require 'lib/user_ldap'
require 'lib/ldap_mixin'


class UserController < ApplicationController
  before_filter :require_user
  before_filter :group_optional

  REQUIRED = {
    'givenname'          => 'First name', 
    'sn'                 => 'Last name',
    'userpassword'       => 'Password',  
    'repeatuserpassword' => 'Repeat Password',
    'mail'               => 'Email' }

  def update
    #uncached from LDAP, so always current
    @ldap_user = User::LDAP.fetch(current_user.login)

    @display_text = ''
    if !params[:givenname].nil? then
      # put updated info in this hash so they don't have to retype
      params.each_pair{|k,v| @ldap_user[k] = v }
      error_fields = REQUIRED.keys.select {|key| params[key].blank? }
      if error_fields.length > 0 then
        @display_text += "The following items must be filled in: "
        @display_text += error_fields.map{|i| REQUIRED[i]}.join(', ' )
        @display_text += "."
      elsif params[:userpassword] != params[:repeatuserpassword] then
        @display_text += "Your password and repeated password do not match."
      else

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        params[:telephonenumber] = nil if (params[:telephonenumber] == "")
        
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        ['givenname', 'sn', 'mail', 'tzregion', 'telephonenumber'].each do |i|

          User::LDAP.replace_attribute(current_user.login, i, params[i])
        end
        ['cn', 'displayname'].each do |i|
          User::LDAP.replace_attribute(current_user.login, i, "#{params['givenname']} #{params['sn']}")
        end
        if params['userpassword'] != '!unchanged' then
          User::LDAP.replace_attribute(current_user.login, 'userpassword', params['userpassword'])
        end
        @display_text = "Your profile has been updated."
      end
    end      
  end
end
