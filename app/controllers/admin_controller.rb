class AdminController < ApplicationController
  before_filter :require_user

  def create_user
    @ldap_user = {'tzregion' => 'America/Los_Angeles'}
    require_group_if_user if !session[:group].nil? or !params[:group].nil? #get group info if it's there
    @error_fields = []
    @display_text = ''
    if !params[:givenname].nil? then
      params.each_pair{|k,v| @ldap_user[k] = v } #stuck updated info in this hash so they don't have to retype
      @required = {'givenname' => 'First name', 'sn' => 'Last name', 'uid' => 'User Id',
                  'userpassword' => 'Password', 'repeatuserpassword' => 'Repeat Password',
                  'mail' => 'Email'}
      @required.each_key do |key|
        if params[key].nil? or params[key].eql?('') then
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
        User::LDAP.add(params[:uid], params[:userpassword], params[:givenname],
                params[:sn], params[:mail])
        ['tzregion', 'telephonenumber', 'institution'].each do |i|
          User::LDAP.replace_attribute(params[:uid], i, params[i])
        end
        @display_text = "This user profile has been created."
        @ldap_user = User::LDAP.fetch(params[:uid])
      end
    end

  end
end
