require 'net/http'
class DuaController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_dua
  
  def require_dua
    if @dua_hash.nil? then
      tmp_dua_file = fetch_to_tempfile(session[:dua_file_uri])
      @dua_hash = Dua.parse_file(tmp_dua_file)
    end
    Dua.dua_hash = @dua_hash
  end
  
  def index 
    if params['commit'].eql?("Accept") then  
      if params[:accept].nil? then
        flash[:message] = 'You must check that you accept the terms.'
        return
      end
      if params[:name].blank? || params[:affiliation].blank? || params[:email].blank? then
        flash[:message] = 'Please enter the required fields'
        return
      end

      if  (params[:email] =~ /^.+@.+$/).nil? then
        flash[:message] = 'You must fill in a valid return email address.'
        return
      end   
      
      to_email = params[:email] + "," +  # need to obtain owner of collection email
                   APP_CONFIG['feedback_email_to'].join(", ")
      DuaMailer.feedback_email(params[:email],
               { 'title'     => @dua_hash["Title"],
                 'to_email'  => to_email,
                  'name'     => params[:name],
                  'body'     => @dua_hash["Terms"]}).deliver
       
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