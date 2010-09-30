require 'rest_client'
require 'ftools'
require 'rdf'

class ObjectController < ApplicationController
  before_filter :require_user, :except => [:jupload_add]
  before_filter :require_group_if_user, :except => [:jupload_add]
  before_filter :require_object, :except => [:add, :upload, :upload_error, :dir_add, :jupload_add]


  def index
    @stored_object = @object[Mrt::Object['hasStoredObject']].first
    @versions = @stored_object[Mrt::Object['versionSeq']].first.to_list
    #files for current version
    @files = @versions[@versions.length-1][Mrt::Version.hasFile]
    @files.delete_if {|file| file[RDF::DC.identifier].to_s[0..10].eql?('system/mrt-')}
    @files.sort! {|x,y| File.basename(x[RDF::DC.identifier].to_s.downcase) <=> File.basename(y[RDF::DC.identifier].to_s.downcase)}
    @total_size = @stored_object[Mrt::Object.totalActualSize].to_s.to_i
  end

  def download
    q = Q.new("?obj rdf:type object:Object .
               ?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?obj")
    
    object = store().select(q)[0]['obj'].to_uri
    object_uri = object.first(Mrt::Base.bytestream).to_uri
    http = Mrt::HTTP.new(object_uri.scheme, object_uri.host, object_uri.port)
    tmp_file = http.get_to_tempfile("#{object_uri.path}?t=zip")
    send_file(tmp_file.path,
              :filename => "#{esc(params[:object])}_object.zip",
              :type => "application/zip",
              :disposition => "download")
  end

  def add
    
  end

  def upload
    new_file = ''
    if params[:file].nil? then
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to :controller => 'object', :action => 'add', :group => params[:group]
      return false
    end
    begin
      new_file = DataFile.save(params[:file], current_user.login)

      hsh = {
          'file'              => File.new(new_file, 'rb'),
          'type'              => params[:object_type],
          'submitter'         => "#{current_user.login}/#{current_user.displayname}",
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
                   #"Accept" => 'application/xml',
                   :multipart => true
                  }
             )

      File.delete(new_file)
      @doc = Nokogiri::XML(response) do |config|
        config.strict.noent.noblanks
      end

      @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
      @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length
    rescue Exception => ex
      File.delete(new_file)
      @doc = Nokogiri::XML(ex.http_body) do |config|
        config.strict.noent.noblanks
      end
      @description = @doc.xpath("//exc:statusDescription")[0].child.text
      render :action => "upload_error"
    end
  end

  def dir_add
  
  end

  def jupload_add
    
  end

end
