require 'tempfile'

class ObjectController < ApplicationController

  include Encoder

  before_filter :require_user,       :except => [:jupload_add, :recent, :ingest, :mint, :update]
  before_filter :require_group,      :except => [:jupload_add, :recent, :ingest, :mint, :update]
  before_filter :require_write,      :only => [:add, :upload]
  before_filter :require_session_object, :only => [:download]
  before_filter :require_mrt_object, :only => [:download]

  before_filter(:only=>[:download]) { require_permissions('download',
                                                          { :action => 'index', 
                                                            :group => flexi_group_id,
                                                            :object =>params[:object] }) }

  protect_from_forgery :except => [:ingest, :mint, :update]

  def require_session_object
    params[:object] = session[:object] if !session[:object].nil? && params[:object].nil?
    session[:version] = nil if !session[:version].nil?  #clear out version
  end
  
  def ingest
    if !current_user then
      render :status=>401, :text=>"" and return
    else
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
          'synchronousMode'   => params[:synchronousMode],
          'type'              => params[:type]
        }.reject{|k, v| v.blank? }
        
        client = HTTPClient.new
        client.receive_timeout = 3600
        client.send_timeout = 3600
        client.connect_timeout = 7200
        client.keep_alive_timeout = 3600
        response = client.post(INGEST_SERVICE, ingest_args, {"Content-Type" => "multipart/form-data"})

        render :status=>response.code, :content_type=>response.headers[:content_type], :text=>response.body
      end
    end
  end

  def update
    if !current_user then
      render :status=>401, :text=>"" and return
    else
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
          'synchronousMode'   => params[:synchronousMode],
          'type'              => params[:type]
        }.reject{|k, v| v.blank? }

        response = RestClient.post(INGEST_SERVICE_UPDATE, ingest_args, { :multipart => true })
        render :status=>response.code, :content_type=>response.headers[:content_type], :text=>response.body
      end
    end  
  end
  
  def mint
    if !current_user then
      render :status=>401, :text=>"" and return
    else
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
        client.receive_timeout = 7200
        response = client.post(MINT_SERVICE, mint_args, {"Content-Type" => "multipart/form-data"})

        render :status=>response.code, :content_type=>response.headers[:content_type], :text=>response.body
      end
    end
  end

  def index
    @object = MrtObject.find_by_primary_id(params[:object])
    @versions = @object.versions
    #files for current version
    @files = @object.files.
      reject {|file| file.identifier.match(/^system\/mrt-/) }.
      sort_by {|x| File.basename(x.identifier.downcase) }    
  end

  def download
    # bypass DUA processing for python scripts (indicated by special param) or if dua has already been accepted
    if params[:blue].nil? 
      #check if user already saw DUA and accepted- if so, skip all this & download the file
      if !session[:perform_download]  
        # if DUA was not accepted, redirect to object landing page 
        if session[:collection_acceptance][@group.id].eql?("not accepted") then
          session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
          redirect_to  :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false
          # if DUA for this collection has not yet been displayed to user, perform logic to retrieve DUA.
          # if persistance is at the session level and user already saw DUA, this section will be skipped
        elsif !session[:collection_acceptance][@group.id] then
          # perform DUA logic to retrieve DUA
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
    end
    
    # if size is > MAX_ARCHIVE_SIZE, redirect to have user enter email for asynch compression (skipping streaming)
    if exceeds_size() then
      #if user canceled out of enterering email redirect to object landing page
      if session[:perform_async].eql?("cancel") then
        session[:perform_async] = false;  #reinitalize flag to false
        redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object] and return false
      elsif session[:perform_async] then #do not stream, redirect to object landing page
        session[:perform_async] = false;  #reinitalize flag to false
        redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object] and return false
      else #allow user to enter email
        store_location
        store_object
        redirect_to :controller => "lostorage",  :action => "index" and return false 
      end
    end

    response.headers["Content-Disposition"] = "attachment; filename=#{Orchard::Pairtree.encode(@object.identifier.to_s)}_object.zip"
    response.headers["Content-Type"] = "application/zip"
    self.response_body = Streamer.new("#{@object.bytestream_uri}?t=zip")
    session[:perform_download] = false  
  end

  def upload
    if params[:file].nil? then
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to :controller => 'object', :action => 'add', :group => flexi_group_id and return false
    end
    begin
      hsh = {
          'file'              => params[:file].tempfile,
          'type'              => params[:object_type],
          'submitter'         => "#{current_user.login}/#{current_user.displayname}",
          'filename'          => params[:file].original_filename,
          'profile'           => @group.submission_profile,
          'creator'           => params[:author],
          'title'             => params[:title],
          'primaryIdentifier' => params[:primary_id],
          'date'              => params[:date],
          'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
          'responseForm'      => 'xml'
        }.reject{|key, value| value.blank? }

      client = HTTPClient.new
      client.receive_timeout = 3600
      client.send_timeout = 3600
      client.connect_timeout = 7200
      client.keep_alive_timeout = 3600
      response = client.post(INGEST_SERVICE_UPDATE, hsh, {"Content-Type" => "multipart/form-data"})

      @doc = Nokogiri::XML(response.content) do |config|
        config.strict.noent.noblanks
      end

      @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
      @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length
    rescue Exception => ex
      # see if we can parse the error from ingest, if not then unknown error
      @doc = Nokogiri::XML(ex.response) do |config|
        config.strict.noent.noblanks
      end
      @description = "ingest: #{@doc.xpath("//exc:statusDescription")[0].child.text}"
      @error = "ingest: #{@doc.xpath("//exc:error")[0].child.text}"
      render :action => "upload_error"
    end
  end

  def recent
    @collection_ark = params[:collection]
    @objects = MrtCollection.
      where(:ark=>@collection_ark).
      first.
      mrt_objects.
      order('last_add_version desc').
      includes(:mrt_versions, :mrt_version_metadata).
      paginate(:page       => (params[:page] || 1), 
               :per_page   => 20)
    respond_to do |format|
      format.html
      format.atom
    end
  end
end
