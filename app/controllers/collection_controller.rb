class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  Q = Mrt::Sparql::Q

  def object_count
    @object_count = my_cache("#{@group.id}_object_count") do
      @group.object_count
    end
    render :partial=>"object_count"
  end

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
    @recent_objects = MrtObject.paginate(:collection => no_inject(@group.sparql_id),
                                         :page       => (params[:page] || 1), 
                                         :per_page   => 10)
  end

  def search_results
    terms = no_inject(Unicode.downcase(params[:terms])).split(/[\s:\/_-]+/)
    terms_q = terms.map {|term| "<http://4store.org/fulltext#token> \"#{term}\"" }.join("; ")
    q = Q.new("?s a object:Object ;
                  #{terms_q} ;
                  base:isInCollection <#{@group.sparql_id}> ;
                  dc:modified ?mod .",
              :select => "DISTINCT ?s",
              :order_by => "DESC(?mod)")
    @results = store().select(q).map{|s| MrtObject.new(s['s']) }.
      paginate(:page=>params[:page], :per_page=>10)
  end
end
