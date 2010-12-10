class ObjectController < ApplicationController
  before_filter :require_user, :except => [:jupload_add, :recent]
  before_filter :require_group, :except => [:jupload_add, :recent]
  before_filter :require_write, :only => [:add, :upload]

  def index
    @object = MrtObject.find_by_identifier(params[:object])
    @versions = @object.versions
    #files for current version
    @files = @object.files
    @files.delete_if {|file| file[RDF::DC.identifier][0].value.match(/^system\/mrt-/) }
    @files = @files.sort_by {|x| File.basename(x[RDF::DC.identifier].to_s.downcase) }
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
              :filename => "#{Pairtree.encode(params[:object])}_object.zip",
              :type => "application/zip",
              :disposition => "attachment")
  end

  def add
  end

  def upload
    if params[:file].nil? then
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to :controller => 'object', :action => 'add', :group => flexi_group_id and return false
    end
    begin
      hsh = {
          'file'              => params[:file],
          'type'              => params[:object_type],
          'submitter'         => "#{current_user.login}/#{current_user.displayname}",
          'filename'          => params[:file].original_filename,
          'profile'           => @group.submission_profile,
          'creator'           => params[:author],
          'title'             => params[:title],
          'date'              => params[:date],
          'localIdentifier'   => params[:local_id], # local identifier necessary, nulls?
          'responseForm'      => 'xml'
        }.reject{|key, value| value.blank? }

      response = RestClient.post(INGEST_SERVICE, hsh, { :multipart => true })
      @doc = Nokogiri::XML(response) do |config|
        config.strict.noent.noblanks
      end

      @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
      @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length
    rescue Exception => ex
      @doc = Nokogiri::XML(ex.http_body) do |config|
        config.strict.noent.noblanks
      end
      @description = @doc.xpath("//exc:statusDescription")[0].child.text
      render :action => "upload_error"
    end
  end

  def recent
    @collection = params[:collection]
    @objects = MrtObject.paginate(:collection => @collection,
                                  :page       => (params[:page] || 1),
                                  :per_page   => 20)
    respond_to do |format|
      format.html
      format.atom
    end
  end
end
