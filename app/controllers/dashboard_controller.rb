class DashboardController < ApplicationController
  before_filter :require_user

  Q = Mrt::Sparql::Q
  def show
    @object_count  = store().select(Q.new("?s rdf:type object:Object")).size
    @version_count = store().select(Q.new("?s rdf:type version:Version")).size
    @file_count    = store().select(Q.new("?s rdf:type file:File")).size
    @total_size    = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum()
    q = Q.new("?so rdf:type object:Object . 
               ?so object:isStoredObjectFor ?s . 
               ?s ?p ?o . 
               ?so dc:modified ?mod .",
              :limit    => 100,
              :select   => "DISTINCT ?s ?mod",
              :order_by => "DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
  end

  def search
    q = Q.new("?s ?p ?o
               FILTER (datatype(?o) = xsd:string)
               FILTER regex(?o, \"#{params[:q]}\", \"i\")")
    @results = store().select(q)
  end
end
