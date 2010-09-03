class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def index
    @object_count = store().select(Q.new("?s rdf:type object:Object")).size
    @version_count = store().select(Q.new("?s rdf:type version:Version")).size
    @file_count = store().select(Q.new("?s rdf:type file:File")).size
    @total_size = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum() #XXX this doesn't work right
    q = Q.new("?so rdf:type object:Object .
               ?so object:isStoredObjectFor ?s .
               ?s ?p ?o .
               ?so dc:modified ?mod .",
               :limit => 100,
               :select => "DISTINCT ?s ?mod",
               :order_by => "DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
  end

  def search_results
    #this doesn't search by arkid :-(
    q = Q.new("?so rdf:type object:Object .
           ?so object:isStoredObjectFor ?s .
           ?s ?p ?o .
           ?so dc:modified ?mod .
           ?so <http://purl.org/dc/terms/identifier> ?so_ident
           FILTER (datatype(?o) = xsd:string) .
           FILTER regex(?o, \"#{params[:terms]}\", \"i\")", # ||
#          FILTER regex(?so_ident, \"#{params[:terms]}\", \"i\")",
           :limit => 100,
           :select => "DISTINCT ?s ?mod ?so_ident",
           :order_by => "DESC(?mod)")
    @results = store().select(q).map{|s| UriInfo.new(s['s']) }
    #@results = store().select(q)
  end
end
