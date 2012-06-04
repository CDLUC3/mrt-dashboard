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
      tmp_file = fetch_to_tempfile("#{@version.bytestream_uri}?t=zip")
      # rails is not setting Content-Length
      response.headers["Content-Length"] = File.size(tmp_file.path).to_s
      send_file(tmp_file.path,
                :filename => "#{Orchard::Pairtree.encode(@object.identifier.to_s)}_version_#{Orchard::Pairtree.encode(@version.identifier.to_s)}.zip",
                :type => "application/zip",
                :disposition => "attachment")
    else
      flash[:error] = 'You do not have permission to download.'     
      redirect_to :action => 'index', :group => flexi_group_id,  :object =>params[:object], :version => params[:version] and return false
   end
  end
end
