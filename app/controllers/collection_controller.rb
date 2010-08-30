class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def index
    @object_count = store().select(Q.new("?s rdf:type object:Object")).size
    @version_count = store().select(Q.new("?s rdf:type version:Version")).size
    @file_count = store().select(Q.new("?s rdf:type file:File")).size
    @total_size = store().select(Q.new("?s dc:extent ?n")).map{|r| r['n'].value.to_i}.sum()
=begin
    q = Q.new("?so rdf:type mrt:StorageObject .
               ?so mrt:isStoredObjectFor ?s .
               ?s ?p ?o .
               ?so dc:modified ?mod .",
              :limit    => 100,
              :select   => "DISTINCT ?s ?mod",
              :order_by => "DESC(?mod)")
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
=end
  end
end
