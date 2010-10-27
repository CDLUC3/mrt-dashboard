class UserController < ApplicationController
  before_filter :require_user

  def update
    #this could be made more efficient and wonderful, but I think that we may be going
    #to a different authentication service soon, so it will all need rewriting, anyway, might as well wait.
    require_group if !session[:group].nil? or !params[:group].nil? #get group info if it's there
    @ldap_user = User::LDAP.fetch(current_user.login) #uncached from LDAP, so always current
    #update if this is submitted with appropriate information
    @error_fields = []
    @display_text = ''
    if !params[:givenname].nil? then
      params.each_pair{|k,v| @ldap_user[k] = v } #stuck updated info in this hash so they don't have to retype
      @required = {'givenname' => 'First name', 'sn' => 'Last name',
                  'userpassword' => 'Password', 'repeatuserpassword' => 'Repeat Password',
                  'mail' => 'Email'}
      @required.each_key do |key|
        if params[key].blank? then
          @error_fields.push(key)
        end
      end
      if @error_fields.length > 0 or !params[:userpassword].eql?(params[:repeatuserpassword]) then
        if @error_fields.length > 0 then
          @display_text += "The following items must be filled in: #{@error_fields.map{|i| @required[i]}.join(', ' )}."
        end
        if !params[:userpassword].eql?(params[:repeatuserpassword]) then
          @display_text += " Your password and repeated password do not match."
        end
      else
        ['givenname', 'sn', 'mail', 'tzregion', 'telephonenumber'].each do |i|
          User::LDAP.replace_attribute(current_user.login, i, params[i])
        end
        #special fields
        User::LDAP.replace_attribute(current_user.login, 'cn', "#{params['givenname']} #{params['sn']}")
        User::LDAP.replace_attribute(current_user.login, 'displayname', "#{params['givenname']} #{params['sn']}")
        if !params['userpassword'].eql?('!unchanged') then
          User::LDAP.replace_attribute(current_user.login, 'userpassword', params['userpassword'])
        end
        @display_text = "Your profile has been updated."
      end
    end
    
  end
end
