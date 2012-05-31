class FileController < ApplicationController
  before_filter :require_user
  before_filter :require_object
  before_filter :require_group
  before_filter :require_version

  def display
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      # determine if user is retrieving a system file; otherwise assume they are obtaining
      # a producer file which needs to prepended to the filename
      if !params[:file].include? "producer"
        if !params[:file].include? "system"
         params[:file].insert(0, "producer/")     
        end
      end
      # the router removes the file extension from the filename - need to add it back on if one exists
      if !params[:format].blank?
        params[:file].concat "." + params[:format]
      end
      
      q = Q.new("?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                      a object:Object .
                 ?vers version:inObject ?obj ;
                       dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                       version:hasFile ?file .
                 ?file dc:identifier \"#{no_inject(params[:file])}\"^^<http://www.w3.org/2001/XMLSchema#string> .",
                :select => "?file")
  
      file = MrtFile.new(store().select(q)[0]['file'])
      file_uri = file.first(Mrt::Model::Base.bytestream).to_uri
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
