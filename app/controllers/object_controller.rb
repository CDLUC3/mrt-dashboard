class ObjectController < ApplicationController
  before_filter :require_user,       :except => [:jupload_add, :recent]
  before_filter :require_group,      :except => [:jupload_add, :recent, :ingest]
  before_filter :require_write,      :only => [:add, :upload]
  before_filter :require_mrt_object, :only => [:download]
  protect_from_forgery :except => [:ingest]

  def ingest
    if !current_user.groups.any? {|g| g.submission_profile == params[:profile]} then
      render :status=>401, :text=>""
    else
      ingest_args = {
        'file'            => params[:file].tempfile,
        'type'            => params[:type],
        'submitter'       => "#{current_user.login}/#{current_user.displayname}",
        'filename'        => params[:file].original_filename,
        'profile'         => params[:profile],
        'creator'         => params[:creator],
        'title'           => params[:title],
        'date'            => params[:date],
        'localIdentifier' => params[:localIdentifier],
        'responseForm'    => params[:responseForm] }
      response = RestClient.post(INGEST_SERVICE, ingest_args, { :multipart => true })
      render :status=>response.code, :content_type=>response.headers[:content_type], :text=>response.body
    end
  end
  
  def index
    @object = MrtObject.find_by_identifier(params[:object])
    @versions = @object.versions
    #files for current version
    @files = @object.files.
      reject {|file| file[RDF::DC.identifier][0].value.match(/^system\/mrt-/) }.
      sort_by {|x| File.basename(x[RDF::DC.identifier].to_s.downcase) }
  end

  def download
    tmp_file = fetch_to_tempfile("#{@object.bytestream_uri}?t=zip")
    # rails is not setting Content-Length
    response.headers["Content-Length"] = File.size(tmp_file.path).to_s
    send_file(tmp_file.path,
              :filename => "#{Orchard::Pairtree.encode(@object.identifier.to_s)}_object.zip",
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
          'file'              => params[:file].tempfile,
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

      #this is for debugging with equivalent request with curl
=begin
      arr_out = []
      hsh.each_pair do |k,v|
        if !k.eql?('file') then
          arr_out.push("-F \"#{k}=#{v}\"")
        end
      end
      puts "\ncurl -F \"file=@#{hsh['file'].path}\" #{arr_out.join(" ")} #{INGEST_SERVICE}\n\n"
=end
      #end for debugging

      @response = RestClient.post(INGEST_SERVICE, hsh, { :multipart => true })

      @doc = Nokogiri::XML(@response) do |config|
        config.strict.noent.noblanks
      end

      @batch_id = @doc.xpath("//bat:batchState/bat:batchID")[0].child.text
      @obj_count = @doc.xpath("//bat:batchState/bat:jobStates").length
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
