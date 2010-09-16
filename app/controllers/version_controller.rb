require 'ftools'
require 'rdf'

class VersionController < ApplicationController
  before_filter :require_user
  before_filter :require_group_if_user
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
    q = Q.new("?vers dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers rdf:type version:Version .
               ?vers version:inObject ?obj .
               ?obj rdf:type object:Object .
               ?obj object:isStoredObjectFor ?meta .
               ?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?vers")
    
    version_uri = store().select(q)[0]['vers'].to_uri
    # HACK 
    version_uri = URI.parse(version_uri.to_s.gsub(/\/state\//, '/content/'))
    http = Mrt::HTTP.new(version_uri.scheme, version_uri.host, version_uri.port)
    tmp_file = http.get_to_tempfile("#{version_uri.path}?t=zip")
    send_file(tmp_file.path,
              :x_sendfile => false,
              :filename => "#{esc(params[:object])}_version_#{esc(params[:version])}.zip",
              :type => "application/zip",
              :disposition => "attachment")
  end
end
