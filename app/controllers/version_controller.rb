require 'ftools'
require 'rdf'

class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_object
  before_filter :require_version

  def index

    @stored_object = @object[Mrt::Object['hasStoredObject']].first
    @versions = @stored_object[Mrt::Object['versionSeq']].first.to_list
    #files for current version
    files = @version[Mrt::Version.hasFile]
    @system_files = []
    @files = []
    files.each do |file|
      if file[RDF::DC.identifier].to_s[0..10].eql?('system/mrt-') then
        @system_files.push(file)
      else
        @files.push(file)
      end
    end
    @files.sort! {|x,y| File.basename(x[RDF::DC.identifier].to_s.downcase) <=> File.basename(y[RDF::DC.identifier].to_s.downcase)}
    @system_files.sort! {|x,y| File.basename(x[RDF::DC.identifier].to_s.downcase) <=> File.basename(y[RDF::DC.identifier].to_s.downcase)}
    
  end

  def download
    dl_uri = "#{STORE_URI}#{esc(params[:object])}/#{esc(params[:version])}"
    fileUri = RDF::URI.new(dl_uri)
    http = Mrt::HTTP.new(fileUri.scheme, fileUri.host, fileUri.port)
    tmp_file = http.get_to_tempfile(fileUri.path)
    send_file(tmp_file.path,
              :filename => "#{esc(params[:object])}_version_#{esc(params[:version])}.tar.gz",
              :type => "application/octet-stream",
              :disposition => 'inline')
  end
end
