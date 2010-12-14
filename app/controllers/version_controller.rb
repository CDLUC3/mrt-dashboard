class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_mrt_version

  def index
    #files for current version
    all_files = @version[Mrt::Version.hasFile].sort_by do |f| 
      f[RDF::DC.identifier].to_s.downcase
    end
    (@system_files, @files) = all_files.partition do |file|
      file[RDF::DC.identifier].to_s.match(/^system\//)
    end
  end

  def download
    tmp_file = fetch_to_tempfile("#{@version.bytestream_uri}?t=zip")
    send_file(tmp_file.path,
              :filename => "#{Pairtree.encode(@object.identifier.to_s)}_version_#{Pairtree.encode(@version.identifier.to_s)}.zip",
              :type => "application/zip",
              :disposition => "attachment")
  end
end
