# TODO: remove this, then remove it from exclude list in top-level .rubocop.yml
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
      (flash[:message] = 'You must fill in a valid return email address.') && return unless params[:user_agent_email] =~ /^.+@.+$/

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
      @title = dua_hash['Title']
      @terms = dua_hash['Terms']
    end
  end
  #:nocov:

  # TODO: is this only used for DUAs? if so, let's remove it
  # rubocop:disable Security/Open
  def with_fetched_tempfile(*args)
    require 'open-uri'
    require 'fileutils'
    # TODO: figure out what we really mean to be opening here, & use more specific methods
    open(*args) do |data|
      tmp_file = Tempfile.new('mrt_http')
      begin
        until (buff = data.read(4096)).nil?
          tmp_file << buff
        end
        tmp_file.rewind
        yield(tmp_file)
      ensure
        tmp_file.close
        tmp_file.delete
      end
    end
  end
  # rubocop:enable Security/Open

end
