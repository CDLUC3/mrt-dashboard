class DashboardController < ApplicationController
  before_filter :require_user

  Q = Mrt::Sparql::Q
  def show
    @object_count  = store().select(Q.new("?s rdf:type mrt:Object")).size
    @version_count = store().select(Q.new("?s rdf:type mrt:StorageVersion")).size
    @file_count    = store().select(Q.new("?s rdf:type mrt:StorageFile")).size
    @total_size    = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum()
    q = Q.new("?so rdf:type mrt:StorageObject . 
               ?so mrt:isStoredObjectFor ?s . 
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
