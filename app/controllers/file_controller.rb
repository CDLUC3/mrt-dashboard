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
      
      # do not process DUA for python scripts - indicated by special param
      # if DUA has been accepted already for this collection, do not display to user again in this session
      debugger
      if params[:blue].nil? then
#        if session[:collection_acceptance][@group.id].eql?("not accepted") then
#           redirect_to  :controller => 'object', :action => 'index', :group => flexi_group_id,  :object =>params[:object] and return false         
#         end
        if !session[:collection_acceptance][@group.id]
            #construct the dua_file_uri based off the file_uri, the object's parent collection, version 0, and  DUA filename
            rx = /^(.*)\/([^\/]+)\/([0-9]+)\/([^\/]+)$/
            dua_file_uri = construct_dua_uri(rx, file_uri)
            uri_response = process_dua_request(dua_file_uri)
            # if the DUA exists, display DUA to user for acceptance before displaying file
             if (uri_response.class == Net::HTTPOK) then
               tmp_dua_file = fetch_to_tempfile(dua_file_uri) 
               session[:dua_file_uri] = dua_file_uri
               store_location
               redirect_to :controller => "dua",  :action => "index" and return false 
           end
         end
      end
      
      # else do nothing - no DUA file so don't need to display DUA, just display file
      tmp_file = fetch_to_tempfile(file_uri)
      # rails is not setting Content-Length
      response.headers["Content-Length"] = File.size(tmp_file.path).to_s
      send_file(tmp_file.path,
                :filename => File.basename(file.identifier),
                :type => file[Mrt::Model::File.mediaType].to_s.downcase,
                :disposition => "inline")
   else
      flash[:error] = 'You do not have permission to download.'     
      redirect_to  :controller => 'version', :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
 end 
end
