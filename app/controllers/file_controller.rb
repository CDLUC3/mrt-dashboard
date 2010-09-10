require 'ftools'
require 'rdf'

class FileController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  before_filter :require_object
  before_filter :require_version

  def display
    q = Q.new("?file dc:identifier \"#{params[:file]}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers version:hasFile ?file .
               ?vers dc:identifier \"#{params[:version]}\"^^<http://www.w3.org/2001/XMLSchema#string> .
               ?vers rdf:type version:Version .
               ?vers version:inObject ?obj .
               ?obj rdf:type object:Object .
               ?obj object:isStoredObjectFor ?meta .
               ?obj dc:identifier \"#{params[:object]}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?file")
    
    res = store().select(q)

    @file = UriInfo.new(res[0]['file'])

    @bytestream = @file[Mrt::File.bytestream]

    redirect_to @bytestream.to_s

  end
end
