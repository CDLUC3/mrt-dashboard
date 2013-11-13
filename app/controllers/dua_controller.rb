class DuaController < ApplicationController
  before_filter :require_user

  def index 
    if params['commit'] == "Accept" then
      dua_hash = Dua.parse_file(fetch_to_tempfile(session[:dua_file_uri]))
      flash[:message] = 'You must check that you accept the terms.' and return if params[:accept].blank?
      if params[:name].blank? || params[:affiliation].blank? || params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields' and return
      end
      if !params[:user_agent_email].match(/^.+@.+$/)
        flash[:message] = 'You must fill in a valid return email address.' and return
      end   
      
      group = InvObject.find_by_ark(params_u(:object)).group
      DuaMailer.dua_email(:to          => params[:user_agent_email],
                          :cc          => APP_CONFIG['dua_email_to'] + [dua_hash["Notification"] || ''],
                          :reply_to    => dua_hash["Notification"],
                          :title       => dua_hash["Title"],
                          :name        => params[:name],
                          :affiliation => params[:affiliation],
                          :object      => params_u(:object),
                          :collection  => group.description,
                          :terms       => dua_hash["Terms"]).deliver
      #user accepted DUA, go ahead and process file/object/version download
      session[:collection_acceptance][group.id] = (dua_hash["Persistence"] || "single")
      # TODO too many slashes here if some params are empty
      redirect_to "/d/#{params[:object]}/#{params[:version]}/#{params[:file]}"
    elsif (params[:commit] == "Do Not Accept") then
      # TODO too many slashes here if some params are empty
      redirect_to "/m/#{params[:object]}/#{params[:version]}"
    else
      dua_hash = Dua.parse_file(fetch_to_tempfile(session[:dua_file_uri]))
      @title, @terms = dua_hash['Title'], dua_hash['Terms']
    end
  end
end
