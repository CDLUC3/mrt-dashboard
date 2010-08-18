#require 'httpclient' #doesn't wor for some reason
require 'rest_client'

class ObjectController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  def add
    
  end

  def upload
    new_file = DataFile.save(params[:file], current_user.login)
=begin
    res = HTTPClient.post(INGEST_SERVICE,
      {
        'file'              => File.new(new_file),
        'type'              => params[:object_type],
        'submitter'         => current_user.displayname,
        'filename'          => params[:file].original_filename,
        'profile'           => 'profileSFISHER', # XXX this needs to be changed
        'creator'           => params[:author],
        'title'             => params[:title],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id],
        'responseForm'      => 'xml'
      })
=end
    render :text => new_file + params.inspect.to_s

  end
end
