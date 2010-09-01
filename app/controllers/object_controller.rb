require 'rest_client'
require 'ftools'
require 'rdf'

class ObjectController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  # the following before_filter :except doesn't work right, see bug report for rails 3 pre
  # at https://rails.lighthouseapp.com/projects/8994/tickets/3913-protect_from_forgery-except-override-in-individual-controllers-isnt-working-in-rails-3pre
  # other people are experienceing it also
  # before_filter :require_object, :except => [:upload]
  # so have to use the more awkward before_filter, :only instead, below
  before_filter :require_object, :only => [:index]

  def index
    @obj_rdf = UriInfo.new("http://#{params[:object]}")
    
  end

  def upload
    new_file = DataFile.save(params[:file], current_user.login)

  #this works for file and container
    hsh = {
        'file'              => File.new(new_file, 'rb'),
        'type'              => params[:object_type],
        'submitter'         => current_user.displayname,
        'filename'          => params[:file].original_filename,
        'profile'           => @group.submission_profile,
        'creator'           => params[:author],
        'title'             => params[:title],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
        'responseForm'      => 'xml'
      }

    hsh.delete_if{|key, value| value.nil? or (value.class == String and value.strip.eql?(''))}

    response = RestClient.post(INGEST_SERVICE,
                hsh,
                {#"Content-Type" => 'application/octet-stream',
                 #"Content-Length" => File.size(new_file),
                 "Accept" => 'application/xml',
                 :multipart => true
                }
           )

    File.delete(new_file)
    @doc = Nokogiri::XML(response) do |config|
      config.strict.noent.noblanks
    end
    
    @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
    @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length

  end
end
