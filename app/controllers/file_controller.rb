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
    
    res = store().select(q)

    @file = UriInfo.new(res[0]['file'])

    fileUri = @file.first(Mrt::File.bytestream).to_uri
    http = Mrt::HTTP.new(fileUri.scheme, fileUri.host, fileUri.port)
    tmp_file = http.get_to_tempfile(fileUri.path)
    send_file(tmp_file.path,
              :filename => File.basename(@file[RDF::DC.identifier].to_s),
              :type => @file[Mrt::File.mediaType].to_s,
              :disposition => 'inline')
  end
end
