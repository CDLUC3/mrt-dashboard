class VersionController < ApplicationController
  before_filter :require_user
  before_filter :load_version
  before_filter(:only => [:download]) do
    if (!has_object_permission?(@version.inv_object, 'download')) then
      flash[:error] = "You do not have download permissions."
      redirect_to(:action=>:index,
                  :object=>@version.inv_object,
                  :version=>@version) and return false
    end
  end

  def load_version
    if (params[:version].to_i == 0) then
      latest_version = InvObject.find_by_ark(params_u(:object)).current_version.number
      redirect_to(:object => params[:object],
                  :version => latest_version)
    else
      @version = InvVersion.joins(:inv_object).
        where("inv_objects.ark = ?", params_u(:object)).
        where("inv_versions.number = ?", params_u(:version).to_i).
        first
      render :status => 404 and return if @version.nil?
    end
  end

  def index
  end

  def download
    # bypass DUA processing for python scripts - indicated by special param
    if params[:blue].nil? then
      session[:collection_acceptance] ||= Hash.new(false)
      #check if user already saw DUA and accepted- if so, skip all this & download the file
      if !session[:perform_download]   
        if !session[:collection_acceptance][@version.inv_object.group.id]
          # perform DUA logic to retrieve DUA
          #construct the dua_file_uri based off the version uri, the object's parent collection, version 0, and  DUA filename
          dua_file_uri = construct_dua_uri(@version.dua_rx, @version.bytestream_uri)
          if process_dua_request(dua_file_uri) then
            # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
            session[:dua_file_uri] = dua_file_uri
            redirect_to(:controller => "dua", :action => "index", :object => @version.inv_object, :version => @version) and return false 
          end
        end
      end
    end

    # if size is > 4GB, redirect to have user enter email for asynch compression (skipping streaming)
    if exceeds_size(@version.inv_object) then
      redirect_to(:controller => "lostorage", :action => "index", :object => @version.inv_object, :version => @version) and return
    end

    stream_response("#{@version.bytestream_uri}?t=zip",
                    "attachment",
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    "application/zip")
    session[:perform_download] = false  
  end
end
