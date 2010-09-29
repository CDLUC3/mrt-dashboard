require 'ruby-debug'

class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group_if_user

  Q = Mrt::Sparql::Q

  def index
    @page_size = 10
    @page = (params[:page] or '1').to_i
    offset = (@page - 1) * @page_size

    @object_count = my_cache("#{@group.id}_object_count") do 
      @group.object_count 
    end

    @version_count = my_cache("#{@group.id}_version_count") do
      @group.version_count
    end

    @file_count = my_cache("#{@group.id}_file_count") do 
      @group.file_count
    end

    @total_size = my_cache("#{@group.id}_total_size") do
      @group.total_size
    end

    q = Q.new("?s a ore:Aggregation ;
                  object:isInCollection <#{no_inject(@group.sparql_id)}> ;
                  dc:modified ?mod .",
               :limit => @page_size,
               :offset => offset,
               :select => "?s",
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
                  dc:modified ?mod .
               ?s ?p ?o .
               FILTER (datatype(?o) = xsd:string) .
               FILTER ( regex(?o, \"#{no_inject(params[:terms])}\", \"i\"))",
              :select => "DISTINCT ?s",
              :order_by => "DESC(?mod)")
    @results = store().select(q)
    @object_count = @results.length
    @results = @results[pg_start..pg_end].map{|s| UriInfo.new(s['s']) }
  end
end
