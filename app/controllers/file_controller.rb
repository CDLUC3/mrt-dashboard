class FileController < ApplicationController
  before_filter :require_user
  before_filter :load_file
  before_filter do
    if (!has_object_permission?(@file.inv_version.inv_object, 'download')) then
      flash[:error] = "You do not have download permissions."
      redirect_to(:action=>:index, 
                  :object=>@file.inv_version.inv_object, 
                  :version=>@file.inv_version) and return false
    end
  end

  def load_file
    filename = params_u(:file)

    # determine if user is retrieving a system file; otherwise assume
    # they are obtaining a producer file which needs to prepended to
    # the filename
    filename = "producer/#{filename}" if !filename.match(/^(producer|system)/)
    # the router removes the file extension from the filename - need to add it back on if one exists
    filename = "#{filename}.#{params[:format]}" if !params[:format].blank?

    @file = InvFile.joins(:inv_version, :inv_object).
      where("inv_objects.ark = ?", params_u(:object)).
      where("inv_versions.number = ?", params[:version]).
      where("inv_files.pathname = ?", filename).
      first
  end

  def download
    # bypass DUA processing for python scripts - indicated by special param
    if params[:blue].nil? then
      session[:collection_acceptance] ||= Hash.new(false)
      #check if user already saw DUA and accepted- if so, skip all this & download the file
      if !session[:perform_download]  
        # if DUA was not accepted, redirect to object landing page 
        if !session[:collection_acceptance][@file.inv_version.inv_object.group.id]
          # perform DUA logic to retrieve DUA
          #construct the dua_file_uri based off the file_uri, the object's parent collection, version 0, and  DUA filename
          dua_file_uri = construct_dua_uri(@file.dua_rx, @file.bytestream_uri)
          if process_dua_request(dua_file_uri) then
          # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
            session[:dua_file_uri] = dua_file_uri
            redirect_to(:controller => "dua", 
                        :action => "index",
                        :object => @file.inv_version.inv_object,
                        :version => @file.inv_version,
                        :file => @file) and return
          end
        end
      end
    end
    
    # the user has accepted the DUA for this collection or there is no DUA to process 
    response.headers["Content-Length"] = @file.full_size.to_s
    response.headers["Content-Disposition"] = "inline; filename=\"#{File.basename(@file.pathname)}\""
    response.headers["Content-Type"] = @file.mime_type

    self.response_body = Streamer.new(@file.bytestream_uri)
    session[:perform_download] = false  
  end 
end
