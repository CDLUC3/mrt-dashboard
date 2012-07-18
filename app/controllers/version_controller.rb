class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_mrt_version

  def index
    #files for current version
    (@system_files, @files) = @version.files.sort_by { |file|
      file.identifier.downcase
    }.partition { |file|
      file.identifier.match(/^system\//)
    }
    @versions = @object.versions
  end

  def download
    # check if user has download permissions 
    if !@permissions.nil? && @permissions.include?('download') then
      filename = "#{Orchard::Pairtree.encode(@object.identifier.to_s)}_version_#{Orchard::Pairtree.encode(@version.identifier.to_s)}.zip"
      response.headers["Content-Type"] = "application/zip"
      response.headers["Content-Disposition"] = "attachment; filename=\"filename\""
      self.response_body = Streamer.new("#{@version.bytestream_uri}?t=zip")
    else
      flash[:error] = 'You do not have permission to download.'     
      redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
  end
end
