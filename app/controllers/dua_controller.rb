class DuaController < ApplicationController
  before_filter :require_user

  #:nocov:
  def index
    object = InvObject.where('inv_objects.ark = ?', params_u(:object)).first
    dua_hash = with_fetched_tempfile(object.dua_uri) { |f| Dua.parse_file(f) }
    if params['commit'] == 'Accept'
      (flash[:message] = 'You must check that you accept the terms.') && return if params[:accept].blank?
      if params[:name].blank? || params[:affiliation].blank? || params[:user_agent_email].blank?
        (flash[:message] = 'Please enter the required fields') && return
      end
      (flash[:message] = 'You must fill in a valid return email address.') && return unless params[:user_agent_email].match(/^.+@.+$/)

      group = object.group
      DuaMailer.dua_email(to: params[:user_agent_email],
                          cc: APP_CONFIG['dua_email_to'] + [dua_hash['Notification'] || ''],
                          reply_to: dua_hash['Notification'],
                          title: dua_hash['Title'],
                          name: params[:name],
                          affiliation: params[:affiliation],
                          object: params_u(:object),
                          collection: group.description,
                          terms: dua_hash['Terms']).deliver
      # user accepted DUA, go ahead and process file/object/version download
      session[:collection_acceptance][group.id] = (dua_hash['Persistence'] || 'single')
      redirect_to mk_merritt_url('d', params[:object], params[:version], params[:file])
    elsif params[:commit] == 'Do Not Accept'
      redirect_to mk_merritt_url('m', params[:object], params[:version])
    else
      @title, @terms = dua_hash['Title'], dua_hash['Terms']
    end
  end
  #:nocov:
end
