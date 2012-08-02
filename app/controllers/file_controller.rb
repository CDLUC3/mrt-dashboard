class FileController < ApplicationController
  before_filter :require_user
  before_filter :require_object
  before_filter :require_group
  before_filter :require_version

  def display
    filename = params[:file]
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      # determine if user is retrieving a system file; otherwise assume they are obtaining
      # a producer file which needs to prepended to the filename
      if !filename.include? "producer"
        if !filename.include? "system"
         filename.insert(0, "producer/")     
        end
      end
      # the router removes the file extension from the filename - need to add it back on if one exists
      if !params[:format].blank?
        filename.concat "." + params[:format]
      end
      
      q = Q.new("?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                      a object:Object .
                 ?vers version:inObject ?obj ;
                       dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                       version:hasFile ?file .
                 ?file dc:identifier \"#{no_inject(filename)}\"^^<http://www.w3.org/2001/XMLSchema#string> .",
                :select => "?file")
  
      file = MrtFile.new(store().select(q)[0]['file'])
      file_uri = file.first(Mrt::Model::Base.bytestream).to_uri
      Rails.logger.info(file_uri)
      
      # bypass DUA processing for python scripts - indicated by special param
      if params[:blue].nil? then
         #check if user already saw DUA and accepted- if so, skip all this & download the file
        if !session[:perform_download]  
          # if DUA was not accepted, redirect to object landing page 
          if session[:collection_acceptance][@group.id].eql?("not accepted") then
            session[:collection_acceptance][@group.id] = false  # reinitialize to false so user can again be given option to accept DUA 
            redirect_to  :controller => 'object', :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false         
          # if DUA for this collection has not yet been displayed to user, perform logic to retrieve DUA.
          # if persistance is at the session level and user already saw DUA, this section will be skipped
          elsif !session[:collection_acceptance][@group.id]
            # perform DUA logic to retrieve DUA
            #construct the dua_file_uri based off the file_uri, the object's parent collection, version 0, and  DUA filename
            rx = /^(.*)\/([^\/]+)\/([0-9]+)\/([^\/]+)$/
            dua_file_uri = construct_dua_uri(rx, file_uri)
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
      end
      
      # the user has accepted the DUA for this collection or there is no DUA to process -  just display file
      dl_url = file.first(Mrt::Model::Base.bytestream).to_uri
      response.headers["Content-Length"] = file.size.to_s
      response.headers["Content-Disposition"] = "inline; filename=\"#{File.basename(file.identifier)}\""
      response.headers["Content-Type"] = file.media_type
      self.response_body = Streamer.new(dl_url)
      session[:perform_download] = false  
   else
      flash[:error] = 'You do not have download permissions.'     
      redirect_to  :controller => 'version', :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
 end 
 
 
end
