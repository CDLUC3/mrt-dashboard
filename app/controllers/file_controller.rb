class FileController < ApplicationController
  before_filter :require_user
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
    tmp_file = fetch_to_tempfile(file_uri)
    # rails is not setting Content-Length
    response.headers["Content-Length"] = File.size(tmp_file.path).to_s
    send_file(tmp_file.path,
              :filename => File.basename(file[RDF::DC.identifier].to_s),
              :type => file[Mrt::File.mediaType].to_s,
              :disposition => "inline")
  end
end
