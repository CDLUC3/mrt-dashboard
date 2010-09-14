require 'rest_client'
require 'ftools'
require 'rdf'

class ObjectController < ApplicationController
  before_filter :require_user
  before_filter :require_group_if_user
  before_filter :require_object, :except => [:add, :upload, :upload_error]


  def index
    #
    @stored_object = @object[Mrt::Object['hasStoredObject']].first
    @versions = @stored_object[Mrt::Object['versionSeq']].first.to_list
    #files for current version
    @files = @versions[@versions.length-1][Mrt::Version.hasFile]
    @files.delete_if {|file| file[RDF::DC.identifier].to_s[0..10].eql?('system/mrt-')}
    @files.sort! {|x,y| File.basename(x[RDF::DC.identifier].to_s.downcase) <=> File.basename(y[RDF::DC.identifier].to_s.downcase)}
    @total_size = @stored_object[Mrt::Object.totalActualSize].to_s.to_i
  end

  def download
    dl_uri = "#{STORE_URI}#{esc(params[:object])}"
    fileUri = RDF::URI.new(dl_uri)
    http = Mrt::HTTP.new(fileUri.scheme, fileUri.host, fileUri.port)
    tmp_file = http.get_to_tempfile("#{fileUri.path}?t=zip")
    send_file(tmp_file.path,
              :filename => "#{esc(params[:object])}_object.zip",
              :type => "application/octet-stream",
              :disposition => 'inline')
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
end
