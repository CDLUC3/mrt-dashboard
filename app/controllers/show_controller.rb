require 'rdf'

class ShowController < ApplicationController
  def show
    @info = UriInfo.new("http://#{params[:id]}")
  end
  
  def view
    @info = UriInfo.new("http://#{params[:id]}")
    fileUri = @info.first(Mrt::File.bytestream).to_uri
    http = Mrt::HTTP.new(fileUri.scheme, fileUri.host, fileUri.port)
    tmp_file = http.get_to_tempfile(fileUri.path)
    send_file(tmp_file.path,
              :filename => File.basename(@info.first(RDF::DC.identifier).value),
              :type => @info.first(Mrt::File['mediaType']),
              :disposition => 'inline')
  end
end
