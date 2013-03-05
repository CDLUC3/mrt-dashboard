require 'tempfile'

class ObjectController < ApplicationController
  before_filter :require_user,       :except => [:jupload_add, :recent, :ingest, :mint]
  before_filter :require_user_or_401, :only => [:ingest, :mint]
  before_filter :require_group,      :except => [:jupload_add, :recent, :ingest, :mint]
  before_filter :require_write,      :only => [:add, :upload]
  before_filter :require_session_object, :only => [:download]
  before_filter :require_mrt_object, :only => [:download]
  protect_from_forgery :except => [:ingest, :mint]

  def require_session_object
    if !session[:object].nil?
      params[:object] = session[:object]
    end
  end
  
  def ingest
    if (!params[:file].respond_to? :tempfile) then
      render(:status=>400, :text=>"Bad file parameter.\n") and return
    elsif !current_user.groups('write').any? {|g| g.submission_profile == params[:profile]} then
      render(:status=>404, :text=>"") and return
    else
      ingest_args = {
        'creator'           => params[:creator],
        'date'              => params[:date],
        'digestType'        => params[:digestType],
        'digestValue'       => params[:digestValue],
        'file'              => params[:file].tempfile,
        'filename'          => (params[:filename] || params[:file].original_filename),
        'localIdentifier'   => params[:localIdentifier],
        'notification'      => params[:notification],
	'notificationFormat'      => params[:notificationFormat],
        'primaryIdentifier' => params[:primaryIdentifier],
        'profile'           => params[:profile],
        'note'              => params[:note],
        'responseForm'      => params[:responseForm],
	'DataCite.resourceType'      => params["DataCite.resourceType"],
	'DC.contributor'    => params["DC.contributor"],
	'DC.coverage'       => params["DC.coverage"],
	'DC.creator'        => params["DC.creator"],
	'DC.date'           => params["DC.date"],
	'DC.description'    => params["DC.description"],
	'DC.format'         => params["DC.format"],
	'DC.identifier'     => params["DC.identifier"],
	'DC.language'       => params["DC.language"],
	'DC.publisher'      => params["DC.publisher"],
	'DC.relation'       => params["DC.relation"],
	'DC.rights'         => params["DC.rights"],
	'DC.source'         => params["DC.source"],
	'DC.subject'        => params["DC.subject"],
	'DC.title'          => params["DC.title"],
	'DC.type'           => params["DC.type"],
        'submitter'         => "#{current_user.login}/#{current_user.displayname}",
        'title'             => params[:title],
        'type'              => params[:type]
      }.reject{|k, v| v.blank? }
      
      client = HTTPClient.new
      client.receive_timeout = 7200    # setting receivetimeout for HTTPClient!
      response = client.post(INGEST_SERVICE, ingest_args, {"Content-Type" => "multipart/form-data"})

      render :status=>response.status, :content_type=>response.headers['Content-Type'], :text=>response.content
    end
  end
  
  def mint
    if !current_user.groups('write').any? {|g| g.submission_profile == params[:profile]} then
      render(:status=>404, :text=>"") and return
    else
      mint_args = {
        'profile'           => params[:profile],
        'erc'              =>  params[:erc] ,
        'file'             =>  Tempfile.new('restclientbug'), 
        'responseForm'     => params[:responseForm]
      }.reject{|k, v| v.blank? }
      
      client = HTTPClient.new
      client.receive_timeout = 7200    # setting receivetimeout for HTTPClient!
      response = client.post(INGEST_SERVICE, mint_args, {"Content-Type" => "multipart/form-data"})

      render :status=>response.status, :content_type=>response.headers['Content-Type'], :text=>response.content
    end
  end

  def index
    @object = MrtObject.find_by_identifier(params[:object])
    @versions = @object.versions
    #files for current version
    @files = @object.files.
      reject {|file| file.identifier.match(/^system\/mrt-/) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def download
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      # bypass DUA processing for python scripts - indicated by special param
      if params[:blue].nil? then
        # if DUA was not accepted, redirect to object landing page 
        if session[:collection_acceptance][@group.id].eql?("not accepted") then
           session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
           redirect_to  :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false
        # if DUA has been accepted already for this collection, do not display to user again in this session
        elsif !session[:collection_acceptance][@group.id]         #process DUA if one exists
           #construct the dua_file_uri based off the object URI, the object's parent collection, version 0, and  DUA filename
           rx = /^(.*)\/([^\/]+)$/  
           dua_file_uri = construct_dua_uri(rx, @object.bytestream_uri)
           uri_response = process_dua_request(dua_file_uri)
           # if the DUA exists, display DUA to user for acceptance before displaying file
           if (uri_response.class == Net::HTTPOK) then
               tmp_dua_file = fetch_to_tempfile(dua_file_uri) 
               session[:dua_file_uri] = dua_file_uri
               store_location
               store_object
               redirect_to :controller => "dua",  :action => "index" and return false 
           end
         end
       end
       
      # the user has accepted the DUA for this collection or there is no DUA to process -  download the object       
      response.headers["Content-Disposition"] = "attachment; filename=#{Orchard::Pairtree.encode(@object.identifier.to_s)}_object.zip"
      response.headers["Content-Type"] = "application/zip"
      self.response_body = Streamer.new("#{@object.bytestream_uri}?t=zip")
    else
      flash[:error] = 'You do not have download permissions'     
      redirect_to  :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false
    end
  end


  def upload
    if params[:file].blank? and params[:dropbox_file].blank? then
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to :controller => 'object', :action => 'add', :group => flexi_group_id and return false
    end
     begin
      use_dropbox = !params[:dropbox_file].blank?
       if use_dropbox
         filename = params[:dropbox_file].split(/\//)[-1]
         manifest = Tempfile.new("mrt-ingest")
         manifest.write("#%checkm_0.7\n")
         manifest.write("#%profile http://uc3.cdlib.org/registry/ingest/manifest/mrt-ingest-manifest\n")
         manifest.write("#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom#\n")
         manifest.write("#%prefix | nfo: | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#\n")
         manifest.write("#%fields | nfo:fileUrl | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:mimeType\n")
         manifest.write("#{params[:dropbox_file]} | | | | | #{filename} | \n")
         manifest.write("#%EOF\n")
         # reset to beginning
         manifest.open
       end
       
       hsh= {
          'file'              => if !use_dropbox then params[:file].tempfile else manifest end,
          'type'              => params[:object_type],
          'submitter'         => "#{current_user.login}/#{current_user.displayname}",
          'filename'          => if !use_dropbox then params[:file].original_filename else nil end,
          'profile'           => @group.submission_profile,
          'creator'           => params[:author],
          'title'             => params[:title],
          'primaryIdentifier' => params[:primary_id],
          'date'              => params[:date],
          'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
          'responseForm'      => 'xml'
        }.reject{|key, value| value.blank? }

      service = (params[:update_object].blank? ? INGEST_SERVICE : INGEST_SERVICE_UPDATE)
      client = HTTPClient.new
      client.receive_timeout = 7200    # setting receivetimeout for HTTPClient!
      response = client.post(INGEST_SERVICE, hsh, {"Content-Type" => "multipart/form-data"})

      @doc = Nokogiri::XML(response.content) do |config|
        config.strict.noent.noblanks
      end

      @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
      @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length
    if defined?(manifest) then
      manifest.close
    end
    rescue Exception => ex
      begin
        # see if we can parse the error from ingest, if not then unknown error
        @doc = Nokogiri::XML(ex.response) do |config|
          config.strict.noent.noblanks
        end
        @description = "ingest: #{@doc.xpath("//exc:statusDescription")[0].child.text}"
        @error = "ingest: #{@doc.xpath("//exc:error")[0].child.text}"
      rescue Exception => ex
        @description = "ui: #{ex.message}"
        @error = ""
      end
      render :action => "upload_error"
    end
  end

  def recent
    @collection_ark = params[:collection]
    @objects = MrtObject.paginate(:collection => RDF_ARK_URI + @collection_ark,
                                  :page       => (params[:page] || 1),
                                  :per_page   => 20)
    respond_to do |format|
      format.html
      format.atom
    end
  end
end
