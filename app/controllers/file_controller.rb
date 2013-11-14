class FileController < ApplicationController
  before_filter :require_user
  before_filter :load_file

  before_filter do
    if (!has_object_permission?(@file.inv_version.inv_object, 'download')) then
      flash[:error] = "You do not have download permissions."
      redirect_to(:controller => :version,
                  :action  => :index, 
                  :object  => @file.inv_version.inv_object, 
                  :version => @file.inv_version) and return false
    end
  end

  before_filter(:only => [:download]) do
    check_dua(@file.inv_version.inv_object,
              { :object  => @file.inv_version.inv_object,
                :version => @file.inv_version,
                :file    => @file})
  end
  
  def download
    stream_response(@file.bytestream_uri, 
                    "inline",
                    File.basename(@file.pathname), 
                    @file.mime_type,
                    @file.full_size)
  end 
  
  private
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
    raise ActiveRecord::RecordNotFound if @file.nil?
  end
end
