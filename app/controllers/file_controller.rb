require 'ftools'
require 'rdf'

class FileController < ApplicationController
  before_filter :require_user, :except=>[:display]
  before_filter :require_group
  before_filter :require_object
  before_filter :require_version

  def display
    q = Q.new("?obj dc:identifier \"#{no_inject(params[:object])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                    a object:Object .
               ?vers version:inObject ?obj ;
                     dc:identifier \"#{no_inject(params[:version])}\"^^<http://www.w3.org/2001/XMLSchema#string> ;
                     version:hasFile ?file .
               ?file dc:identifier \"#{no_inject(params[:file])}\"^^<http://www.w3.org/2001/XMLSchema#string> .",
              :select => "?file")

    file = UriInfo.new(store().select(q)[0]['file'])
    file_uri = file.first(Mrt::Base.bytestream).to_uri
    http = Mrt::HTTP.new(file_uri.scheme, file_uri.host, file_uri.port)
    tmp_file = http.get_to_tempfile(file_uri.path)
    send_file(tmp_file.path,
              :filename => File.basename(file[RDF::DC.identifier].to_s),
              :type => file[Mrt::File.mediaType].to_s,
              :disposition => 'inline')
  end
end
