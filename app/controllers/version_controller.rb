class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_session_object_version,  :only => [:download]
  before_filter :require_mrt_object
  before_filter :require_mrt_version
  before_filter :require_size,                    :only => [:download]

  def require_session_object_version
    params[:object] = session[:object] if !session[:object].nil? && params[:object].nil?
    params[:version] = session[:version] if !session[:version].nil? && params[:version].nil?
  end

  def index
    #files for current version
    (@system_files, @files) = @version.files.sort_by { |file|
      file.identifier.downcase
    }.partition { |file|
      file.identifier.match(/^system\//)
    }
    @versions = @object.versions
    # construct the permalink to this version - use the constant defined in config for stage and prod environments
    @relative_link = "/m/" + urlencode(@object.identifier.to_s) + "/" + @version.identifier
    if Rails.env.production? or Rails.env.stage? then
       @permalink = MERRITT_SERVER + @relative_link
     else
       @permalink = "http://" + request.env["SERVER_NAME"] + @relative_link
     end
  end

  def download
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      # bypass DUA processing for python scripts - indicated by special param
          if params[:blue].nil? then
        #check if user already saw DUA and accepted- if so, skip all this & download the file
        if !session[:perform_download]   
          # if DUA was not accepted, redirect to object landing page 
          if session[:collection_acceptance][@group.id].eql?("not accepted") then
            session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
            redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
          # if DUA for this collection has not yet been displayed to user, perform logic to retrieve DUA.
          # if persistance is at the session level and user already saw DUA, this section will be skipped
          elsif !session[:collection_acceptance][@group.id]
            # perform DUA logic to retrieve DUA
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
      end

       # if size is > 4GB, redirect to have user enter email for asynch compression (skipping streaming)
       if @exceeds_size then
         #if user canceled out of enterering email redirect to object landing page
         if session[:perform_async].eql?("cancel") then
           session[:perform_async] = false;  #reinitalize flag to false
           redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object], :version => params[:version] and return false
         elsif session[:perform_async] then #do not stream, redirect to object landing page
           session[:perform_async] = false;  #reinitalize flag to false
           redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object], :version => params[:version]  and return false
         else #allow user to enter email
           store_location
           store_object
           store_version
           redirect_to :controller => "lostorage",  :action => "index" and return false 
         end
       end

      filename = "#{Orchard::Pairtree.encode(@object.identifier.to_s)}_version_#{Orchard::Pairtree.encode(@version.identifier.to_s)}.zip"
      response.headers["Content-Type"] = "application/zip"
      response.headers["Content-Disposition"] = "attachment; filename= #{filename}"
      self.response_body = Streamer.new("#{@version.bytestream_uri}?t=zip")    
      session[:perform_download] = false  
    else
      flash[:error] = 'You do not have permission to download.'     
      redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
  end
end
