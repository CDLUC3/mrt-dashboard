class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def index
    @object_count = @group.object_count

    @version_count = @group.version_count

    @file_count = @group.file_count

    @total_size = @group.total_size
    
    q = Q.new("?so rdf:type object:Object .
               ?so object:isStoredObjectFor ?s .
               ?s ?p ?o .
               ?s object:isInCollection <#{@group.sparql_id}> .
               ?so dc:modified ?mod .",
               :limit => 100,
               :select => "DISTINCT ?s ?mod",
               :order_by => "DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
  end

  def search_results
    q = Q.new("?so rdf:type object:Object .
           ?so object:isStoredObjectFor ?s .
           ?s ?p ?o .
           ?so dc:modified ?mod .
           ?so dc:identifier ?so_ident
           FILTER (datatype(?o) = xsd:string) .
           FILTER ( regex(?o, \"#{params[:terms]}\", \"i\") || regex(str(?so_ident), \"#{params[:terms]}\", \"i\") )",
           :limit => 100,
           :select => "DISTINCT ?s ?mod ?so_ident",
           :order_by => "DESC(?mod)")
    @results = store().select(q).map{|s| UriInfo.new(s['s']) }
    #@results = store().select(q)
  end
end
