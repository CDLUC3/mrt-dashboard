require 'httpclient'
require "ruby-multipart-post"
require 'rest_client'
require 'ftools'

class ObjectController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  def index
    
  end

  def upload
    new_file = DataFile.save(params[:file], current_user.login)

=begin
    #httpclient version
    hsh = {
        'file'              => File.new(new_file),
        'type'              => params[:object_type],
        'submitter'              => current_user.displayname, # is this user in mark's example (submitter)
        'filename'          => params[:file].original_filename, # is this necessary?
        'profile'           => 'profileSFISHER', # XXX this needs to be changed
        'creator'           => params[:author],
        'title'             => params[:title],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
        'responseForm'      => 'xml'
      }
=end
=begin
  #ruby multipart post version
        hsh = {
        'file'              => FileUploadIO.new(new_file, 'application/octet-stream'),
        'type'              => params[:object_type],
        'submitter'              => current_user.displayname, # is this user in mark's example (submitter)
        'filename'          => params[:file].original_filename, # is this necessary?
        'profile'           => 'profileSFISHER', # XXX this needs to be changed
        'creator'           => params[:author],
        'title'             => params[:title],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
        'responseForm'      => 'xml'
      }
=end

   #rest client version
    hsh = {
        'type'              => params[:object_type],
        'submitter'         => current_user.displayname, # is this user in mark's example (submitter)
        'filename'          => params[:file].original_filename, # is this necessary?
        'profile'           => 'profileSFISHER', # XXX this needs to be changed
        'creator'           => params[:author],
        'title'             => params[:title],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
        'responseForm'      => 'xml'
      }

    hsh.delete_if{|key, value| value.nil? or (value.class == String and value.strip.eql?(''))}

    #res = HTTPClient.post(INGEST_SERVICE, hsh)

    #multipart_post = MultiPart::Post.new(hsh)
    #res = multipart_post.submit(INGEST_SERVICE)

    #res = RestClient.post(INGEST_SERVICE, hsh)
    res = RestClient.post(INGEST_SERVICE,
                {:file => File.new(new_file, 'rb')
                }.merge(hsh),
                {#"Content-Type" => 'application/octet-stream',
                 #"Content-Length" => File.size(new_file),
                 "Accept" => 'application/xml',
                 :multipart => true
                }
           ) #close arguments to Restclient.post

    debugger
    render :text => new_file + params.inspect.to_s

  end
end
