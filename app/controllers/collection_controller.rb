class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def version_count
    @version_count = my_cache("#{@group.id}_version_count") do
      @group.version_count
    end
    render :partial=>"version_count"
  end

  def file_count
    @file_count = my_cache("#{@group.id}_file_count") do 
      @group.file_count
    end
    render :partial=>"file_count"
  end

  def total_size
    @total_size = my_cache("#{@group.id}_total_size") do
      @group.total_size
    end
    render :partial=>"total_size"
  end

  def index
    @page_size = 10
    @page = (params[:page] or '1').to_i
    offset = (@page - 1) * @page_size

    @object_count = my_cache("#{@group.id}_object_count") do   
      @group.object_count 
    end

    q = Q.new("?s a ore:Aggregation ;
                  base:isInCollection <#{no_inject(@group.sparql_id)}> ;
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

    terms = no_inject(Unicode.downcase(params[:terms])).split(/[\s:\/_-]+/)
    terms_q = terms.map {|term| "<http://4store.org/fulltext#token> \"#{term}\"" }.join("; ")

    q = Q.new("?s a ore:Aggregation ;
                  #{terms_q} ;
                  base:isInCollection <#{@group.sparql_id}> ;
                  dc:modified ?mod .",
              :select => "DISTINCT ?s",
              :order_by => "DESC(?mod)")
    @results = store().select(q)
    @object_count = @results.length
    @results = @results[pg_start..pg_end].map{|s| UriInfo.new(s['s']) }
  end
end
