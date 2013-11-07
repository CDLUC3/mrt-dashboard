class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_session_object_version,  :only => [:download]
  before_filter :require_inv_object, :only => [:download]
  before_filter :require_inv_version
  before_filter :require_download_permissions,    :only => [:download]

  include Encoder

  def require_inv_version
    if (params[:version].to_i == 0) then
      latest_version = InvObject.find_by_ark(params[:object]).current_version.number
      redirect_to(:object => urlencode_mod(params[:object]),
                  :version => latest_version)
    else
      @version = InvVersion.joins(:inv_object).
        where("inv_objects.ark = ?", params[:object]).
        where("inv_versions.number = ?", params[:version].to_i).
        first
      render :status => 404 and return if @version.nil?
    end
  end

  def require_session_object_version
    params[:object] = session[:object] if !session[:object].nil? && params[:object].nil?
    params[:version] = session[:version] if !session[:version].nil? && params[:version].nil?
  end

  def index
  end

  def download
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
    if exceeds_size() then
      #if user canceled out of enterering email redirect to object landing page
      if session[:perform_async].eql?("cancel") then
        session[:perform_async] = false;  #reinitalize flag to false
        redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object], :version => params[:version] and return false
      elsif session[:perform_async] then #do not stream, redirect to object landing page
        session[:perform_async] = false;  #reinitalize flag to false
        redirect_to  :action => 'index', :group => flexi_group_id, :object =>params[:object], :version => params[:version]  and return false
      else #allow user to enter email
        session[:redirect_to] = url_for(:action => 'display', :version => @version, :object => @version.inv_object)
        store_object
        store_version
        redirect_to :controller => "lostorage",  :action => "index" and return false 
      end
    end

    filename = "#{Orchard::Pairtree.encode(@version.inv_object.identifier.to_s)}_version_#{Orchard::Pairtree.encode(@version.identifier.to_s)}.zip"
    response.headers["Content-Type"] = "application/zip"
    response.headers["Content-Disposition"] = "attachment; filename= #{filename}"
    self.response_body = Streamer.new("#{@version.bytestream_uri}?t=zip")    
    session[:perform_download] = false  
  end
end
