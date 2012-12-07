class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

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
    @recent_objects = MrtObject.joins(:mrt_collections).
      where("mrt_collections.ark = ?", @group.ark_id).
      order('last_add_version desc').
      includes(:mrt_versions, :mrt_version_metadata).
      paginate(:page       => (params[:page] || 1), 
               :per_page   => 10)
  end

  def search_results
    terms = Unicode.downcase(params[:terms]).gsub('%', '\%').gsub('_', '\_').split(/\s+/)
    terms_q = terms.map{|t| "%#{t}%" }
    @results = MrtObject.paginate(:page=>params[:page], :per_page=>10)
    terms_q.each do |q|
      @results = @results.where("primary_id LIKE ? OR local_id LIKE ?", q, q)
    end
  end
end
