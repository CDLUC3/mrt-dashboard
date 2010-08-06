class ObjectsController < ApplicationController
  Q = Mrt::Sparql::Q
  def recent
    start = params[:start].to_i
    q = Q.new("?so rdf:type mrt:StorageObject . 
               ?so mrt:isStoredObjectFor ?s . 
               ?s ?p ?o . 
               ?so dc:modified ?mod .",
              :limit    => 10,
              :offset   => start,
              :select   => "DISTINCT ?s ?mod",
              :order_by => "DESC(?mod)")

    @next_start = start + 10
    @previous_start = if start == 0 then 0 else start - 10 end
    @recent_objects = store().select(q).map{|s| UriInfo.new(s['s']) }
    respond_to do |format|
      format.html
      format.atom
    end
  end
end
