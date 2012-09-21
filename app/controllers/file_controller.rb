class FileController < ApplicationController
  before_filter :require_user
  before_filter :require_object
  before_filter :require_group
  before_filter :require_download_permissions

  def display
    filename = params[:file]
    # determine if user is retrieving a system file; otherwise assume they are obtaining
    # a producer file which needs to prepended to the filename
    filename = "producer/#{filename}" if !filename.match(/^(producer|system)/)

    # the router removes the file extension from the filename - need to add it back on if one exists
    filename = "#{filename}.#{params[:format]}" if !params[:format].blank?

    file = MrtObject.where(:primary_id=>params[:object]).first.
      versions.where(:version_number=>params[:version]).first.
      files.where(:filename=>filename).first

    # bypass DUA processing for python scripts - indicated by special param
    if params[:blue].nil? then
      # if DUA was not accepted, redirect to object landing page 
      if session[:collection_acceptance][@group.id].eql?("not accepted") then
        session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
        redirect_to  :controller => 'object', :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false         
        # if DUA for this collection has not yet been displayed to user, perform logic to retrieve DUA.
      elsif !session[:collection_acceptance][@group.id]
        dua_file_uri = construct_dua_uri
        uri_response = process_dua_request(dua_file_uri)
        # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
        if (uri_response.class == Net::HTTPOK) then
          tmp_dua_file = fetch_to_tempfile(dua_file_uri) 
          session[:dua_file_uri] = dua_file_uri
          store_location
          redirect_to :controller => "dua",  :action => "index" and return false 
        end
      end
    end

    response.headers["Content-Length"] = file.size.to_s
    response.headers["Content-Disposition"] = "inline; filename=\"#{File.basename(file.identifier)}\""
    response.headers["Content-Type"] = file.media_type
    self.response_body = Streamer.new(file.bytestream_uri)
  end
end 
