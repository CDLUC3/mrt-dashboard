class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_session_object_version, :only => [:download]
  before_filter :require_mrt_version

  def require_session_object_version
    if !session[:object].nil?
      params[:object] = session[:object]
    end
    if !session[:version].nil?
      params[:version] = session[:version]
    end
  end

  def index
    #files for current version
    (@system_files, @files) = @version.files.sort_by { |file|
      file.identifier.downcase
    }.partition { |file|
      file.identifier.match(/^system\//)
    }
    @versions = @object.versions
    @relative_link = "/m/" + urlencode(@object.identifier.to_s) + "/" + @version.identifier
    @permalink = "http://" + request.env["HTTP_HOST"] + @relative_link
  end

  def download
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      # bypass DUA processing for python scripts - indicated by special param
      if params[:blue].nil? then
        # if DUA was not accepted, redirect to object landing page 
        if session[:collection_acceptance][@group.id].eql?("not accepted") then
          session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
          redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
        # if DUA for this collection has not yet been displayed to user, perform logic to retrieve DUA.
        elsif !session[:collection_acceptance][@group.id]
          #construct the dua_file_uri based off the version uri, the object's parent collection, version 0, and  DUA filename
          rx = /^(.*)\/([^\/]+)\/([0-9]+)$/  
          dua_file_uri = construct_dua_uri(rx, @version.bytestream_uri)
          uri_response = process_dua_request(dua_file_uri)
          # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
          if (uri_response.class == Net::HTTPOK) then
             tmp_dua_file = fetch_to_tempfile(dua_file_uri) 
             session[:dua_file_uri] = dua_file_uri
             store_location
             store_object
             store_version
             redirect_to :controller => "dua",  :action => "index" and return false 
          end
        end
      end

      tmp_file = fetch_to_tempfile("#{@version.bytestream_uri}?t=zip")
      # rails is not setting Content-Length
      response.headers["Content-Length"] = File.size(tmp_file.path).to_s
      send_file(tmp_file.path,
                :filename => "#{Orchard::Pairtree.encode(@object.identifier.to_s)}_version_#{Orchard::Pairtree.encode(@version.identifier.to_s)}.zip",
                :type => "application/zip",
                :disposition => "attachment")
    else
      flash[:error] = 'You do not have permission to download.'     
      redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
  end
end
