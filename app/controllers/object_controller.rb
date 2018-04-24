require 'tempfile'

class ObjectController < ApplicationController

  before_filter :require_user,       :except => [:jupload_add, :recent, :ingest, :mint, :update]
  before_filter :load_object, :only=> [:index, :download, :downloadUser, :downloadManifest, :async]
  before_filter(:only=>[:download, :downloadUser, :downloadManifest, :async]) do
    if (!has_object_permission?(@object, 'download')) then
      flash[:error] = "You do not have download permissions."
      render :file => "#{Rails.root}/public/401.html", :status => 401, :layout => false
    end
  end

  before_filter(:only=>[:index]) do
    if (!has_object_permission_no_embargo?(@object, 'read')) then
      render :file => "#{Rails.root}/public/401.html", :status => 401, :layout => false
    end
  end

  before_filter(:only => [:download, :downloadUser]) do
    check_dua(@object, {:object => @object})
  end

  before_filter(:only => [:download]) do
    # Interactive large object download does not support userFriendly
    # Call controller directly

    # if size is > max_archive_size, redirect to have user enter email for asynch compression (skipping streaming)
    if exceeds_sync_size(@object) then
      redirect_to(:controller => "lostorage", :action => "index", :object => @object)
    end
  end

  protect_from_forgery :except => [:ingest, :mint, :update]

  def load_object
    @object = InvObject.where("ark = ?", params_u(:object)).includes(:inv_collections, :inv_versions=>[:inv_files]).first 
    raise ActiveRecord::RecordNotFound if @object.nil?
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
          'submitter'         => (params["submitter"] || "#{current_user.login}/#{current_user.displayname}"),
          'title'             => params[:title],
          'synchronousMode'   => params[:synchronousMode],
          'retainTargetURL'   => params[:retainTargetURL],
          'type'              => params[:type]
        }.reject{|k, v| v.blank? }
        resp = mk_httpclient.post(APP_CONFIG['ingest_service'], ingest_args, {"Content-Type" => "multipart/form-data"})
        render :status=>resp.status, :content_type=>resp.headers[:content_type], :text=>resp.body
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
          'retainTargetURL'   => params[:retainTargetURL],
          'type'              => params[:type]
        }.reject{|k, v| v.blank? }
        resp = mk_httpclient.post(APP_CONFIG['ingest_service_update'], ingest_args, {"Content-Type" => "multipart/form-data"})
        render :status=>resp.status, :content_type=>resp.headers[:content_type], :text=>resp.body
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
        resp = mk_httpclient.post(APP_CONFIG['mint_service'], mint_args, {"Content-Type" => "multipart/form-data"})
        render :status=>resp.status, :content_type=>resp.headers[:content_type], :text=>resp.body
      end
    end
  end

  def index
  end

  def download
    stream_response("#{@object.bytestream_uri}?t=zip", 
                    "attachment",
                    "#{Orchard::Pairtree.encode(@object.ark.to_s)}_object.zip",
                    "application/zip")
  end

  def downloadUser
    stream_response("#{@object.bytestream_uri2}?t=zip", 
                    "attachment",
                    "#{Orchard::Pairtree.encode(@object.ark.to_s)}_object.zip",
                    "application/zip")
  end

  def downloadManifest
    stream_response("#{@object.bytestream_uri3}", 
                    "attachment",
                    "#{Orchard::Pairtree.encode(@object.ark.to_s)}",
                    "text/xml")
  end

  def async
    if exceeds_sync_size(@object) then
      # Async Supported
      render :nothing => true, :status => 200
    else
      # Async Not Acceptable
      render :nothing => true, :status => 406
    end
  end

  def upload
    if params[:file].nil? then
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to :controller => 'object', :action => 'add', :group => current_group and return false
    end
    begin
      ingest_params = {
        'file'              => params[:file].tempfile,
        'type'              => params[:object_type],
        'submitter'         => "#{current_user.login}/#{current_user.displayname}",
        'filename'          => params[:file].original_filename,
        'profile'           => current_group.submission_profile,
        'creator'           => params[:author],
        'title'             => params[:title],
        'primaryIdentifier' => params[:primary_id],
        'date'              => params[:date],
        'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
        'responseForm'      => 'xml'
      }.reject{|key, value| value.blank? }
      resp = mk_httpclient.post(APP_CONFIG['ingest_service_update'], ingest_params)
      @doc = Nokogiri::XML(resp.content) do |config|
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

    # prevent stack trace when collection does not exist
    c = InvCollection.where(:ark=>@collection_ark).first
    if c.nil? || c.to_s == "" then
       render(:status=>404, :text=>"404 Not Found") and return
    end
    @objects = c.inv_objects.
      quickloadhack.
      order('inv_objects.modified desc').
      includes(:inv_versions, :inv_dublinkernels).
      paginate(paginate_args)
    respond_to do |format|
      format.html
      format.atom
    end
  end
  
  private
  def mk_httpclient
    client = HTTPClient.new
    client.receive_timeout = 7200
    client.send_timeout = 3600
    client.connect_timeout = 7200
    client.keep_alive_timeout = 3600
    client
  end
end
