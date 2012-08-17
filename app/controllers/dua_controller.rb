class DuaController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  
  def index 
    @dua_hash =
      Dua.parse_file(fetch_to_tempfile(session[:dua_file_uri]))

    if params['commit'].eql?("Accept") then  
      if params[:accept].nil? then
        flash[:message] = 'You must check that you accept the terms.'
        return
      end
      if params[:name].blank? || params[:affiliation].blank? || params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields'
        return
      end

      if  (params[:user_agent_email] =~ /^.+@.+$/).nil? then
        flash[:message] = 'You must fill in a valid return email address.'
        return
      end   
      
      # configure the email
      to_email = [params[:user_agent_email] , 
                 (@dua_hash["Notification"]  || ''),
                 APP_CONFIG['dua_email_to']].join(", ")
                 
      DuaMailer.dua_email(@dua_hash,
              {'title'      => @dua_hash["Title"],
               'to_email'   => to_email,
               'name'       => params[:name],
               'affiliation'=> params[:affiliation],
               'email'      => params[:user_agent_email],
               'object'     => session[:object],
               'collection' => @group.description, 
               'body'     => @dua_hash["Terms"]
                  }).deliver
       
      #user accepted DUA, go ahead and process file/object/version download
      session[:collection_acceptance][@group.id] = true
       # return to where user came from 
       redirect_to session[:return_to]
    elsif params[:commit].eql?("Do Not Accept") then
       puts "did not accept DUA"
       session[:collection_acceptance][@group.id] = "not accepted"
       # return to where user came from 
       redirect_to session[:return_to]
    end
   end
end
