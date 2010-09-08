class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def index
    @object_count = store().select(Q.new("?obj rdf:type object:Object .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{@group.sparql_id}>")).size

    @version_count = store().select(Q.new("?vers rdf:type version:Version .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{@group.sparql_id}>")).size

    @file_count = store().select(Q.new("?file rdf:type file:File .
        ?file file:inVersion ?vers .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{@group.sparql_id}>")).size

    q = Q.new("?obj rdf:type object:Object .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{@group.sparql_id}>",
      :select => "?obj")

    obs = store().select(q).map{|s| UriInfo.new(s['obj']) }

    @total_size = 0
    
    obs.each{|ob| @total_size += ob[Mrt::Object.totalActualSize].to_s.to_i}

    #@total_size = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum() #XXX this doesn't work right
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
