require 'ftools'
require 'rdf'

class FileController < ApplicationController
  before_filter :require_user
  before_filter :require_group_if_user
  before_filter :require_object
  before_filter :require_version

  def display
    q = Q.new("?file dc:identifier \"#{no_inject(params[:file])}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers version:hasFile ?file .
               ?vers dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers rdf:type version:Version .
               ?vers version:inObject ?obj .
               ?obj rdf:type object:Object .
               ?obj object:isStoredObjectFor ?meta .
               ?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?file")
    
    file = UriInfo.new(store().select(q)[0]['file'])
    file_uri = file.first(Mrt::File.bytestream).to_uri
    http = Mrt::HTTP.new(file_uri.scheme, file_uri.host, file_uri.port)
    tmp_file = http.get_to_tempfile(file_uri.path)
    send_file(tmp_file.path,
              :filename => File.basename(file[RDF::DC.identifier].to_s),
              :type => file[Mrt::File.mediaType].to_s,
              :disposition => 'inline')
  end
end
