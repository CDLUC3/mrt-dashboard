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
    q = Q.new("?vers dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers rdf:type version:Version .
               ?vers version:inObject ?obj .
               ?obj rdf:type object:Object .
               ?obj object:isStoredObjectFor ?meta .
               ?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?vers")
    
    version = store().select(q)[0]['vers'].to_uri
    version_uri = version.first(Mrt::Base.bytestream).to_uri
    http = Mrt::HTTP.new(version_uri.scheme, version_uri.host, version_uri.port)
    tmp_file = http.get_to_tempfile("#{version_uri.path}?t=zip")
    send_file(tmp_file.path,
              :filename => "#{Pairtree.encode(params[:object])}_version_#{Pairtree.encode(params[:version])}.zip",
              :type => "application/zip",
              :disposition => "attachment")
  end
end
