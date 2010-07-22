class DashboardController < ApplicationController
  before_filter :require_user

  Q = Mrt::Sparql::Q
  def show
    @object_count  = store().select(Q.new("?s rdf:type mrt:Object", :select=>"COUNT(?s) as c")).map{|r| r['c']}[0].value
    @version_count = store().select(Q.new("?s rdf:type mrt:StorageVersion", :select=>"COUNT(?s) as c")).map{|r| r['c']}[0].value
    @file_count = store().select(Q.new("?s rdf:type mrt:StorageFile", :select=>"COUNT(?s) as c")).map{|r| r['c']}[0].value
    @total_size    = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum()
    q = Q.new("?so rdf:type mrt:StorageObject . 
               ?so mrt:isStoredObjectFor ?s . 
               ?s ?p ?o . 
               ?so dc:modified ?mod .",
              :limit    =>100,
              :select   =>"DISTINCT ?s",
              :order_by =>"DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
  end
end
