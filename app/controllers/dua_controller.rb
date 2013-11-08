require 'net/http'
class DuaController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_dua

  include Encoder

  def require_dua
    @dua_hash ||= Dua.parse_file(fetch_to_tempfile(session[:dua_file_uri]))
  end
  
  def index 
    if params['commit'].eql?("Accept") then  
      flash[:message] = 'You must check that you accept the terms.' and return if params[:accept].blank?
      if params[:name].blank? || params[:affiliation].blank? || params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields' and return
      end
      if !params[:user_agent_email].match(/^.+@.+$/)
        flash[:message] = 'You must fill in a valid return email address.' and return
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
               'object'     => params[:object],
               'collection' => @group.description, 
               'body'     => @dua_hash["Terms"]
                  }).deliver
       
      #user accepted DUA, go ahead and process file/object/version download
      # set the persistence flag for session level so DUA doesn't get displayed again for this session
      if @dua_hash["Persistence"].eql?("session") then
         session[:collection_acceptance][@group.id] = true
      end
      # return to where user came from 
      session[:perform_download] = true
      # TODO too many slashes here if some params are empty
      redirect_to "/d/#{urlencode_mod(params[:object])}/#{params[:version]}/#{params[:file]}"
    elsif params[:commit].eql?("Do Not Accept") then
      session[:collection_acceptance][@group.id] = "not accepted"
      # TODO too many slashes here if some params are empty
      redirect_to "/d/#{urlencode_mod(params[:object])}/#{params[:version]}/#{params[:file]}"
    end
   end
end
