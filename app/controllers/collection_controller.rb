require 'ruby-debug'

class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group_if_user

  Q = Mrt::Sparql::Q

  def index
    @page_size = 10
    @page = (params[:page] or '1').to_i
    offset = (@page - 1) * @page_size

    @object_count = @group.object_count

    @version_count = @group.version_count

    @file_count = @group.file_count

    @total_size = @group.total_size
    
    q = Q.new("?so rdf:type object:Object .
               ?so object:isStoredObjectFor ?s .
               ?s ?p ?o .
               ?s object:isInCollection <#{no_inject(@group.sparql_id)}> .
               ?so dc:modified ?mod",
               :limit => @page_size,
               :offset => offset,
               :select => "DISTINCT ?s ?mod",
               :order_by => "DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
  end

  def search_results
    @page_size = 10
    @page = (params[:page] or '1').to_i
    pg_start = (@page -1) * @page_size
    pg_end = @page * @page_size - 1

    q = Q.new("?s a ore:Aggregation ;
                  object:isInCollection <#{@group.sparql_id}> ;
                  ?p ?o .
               OPTIONAL { ?s dc:modified ?mod } .
               FILTER (datatype(?o) = xsd:string) .
               FILTER ( regex(?o, \"#{no_inject(params[:terms])}\", \"i\") || 
                        regex(str(?s), \"#{no_inject(params[:terms])}\", \"i\") )",
              :select => "DISTINCT ?s ?mod",
              :order_by => "DESC(?mod)")
    @results = store().select(q)
    @object_count = @results.length
    @results = @results[pg_start..pg_end].map{|s| UriInfo.new(s['s']) }
  end
end
