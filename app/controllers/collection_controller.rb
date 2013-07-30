class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group, :only=>[:index, :search_results]

  def object_count
    @object_count = my_cache("#{session[:group_id]}_object_count") do
      current_group.object_count
    end
    render :partial=>"object_count"
  end

  def version_count
    @version_count = my_cache("#{session[:group_id]}_version_count") do
      current_group.version_count
    end
    render :partial=>"version_count"
  end

  def file_count
    @file_count = my_cache("#{session[:group_id]}_file_count") do 
      current_group.file_count
    end
    render :partial=>"file_count"
  end

  def total_size
    @total_size = my_cache("#{session[:group_id]}_total_size") do
      current_group.total_size
    end
    render :partial=>"total_size"
  end

  
  def index
    #redirect objects to the object controller
    if !params[:object].nil? then
      redirect_to :controller=>'object', :action=>'index', :group=>params[:group], :object=>params[:object]
    end

    @recent_objects = MrtObject.joins(:mrt_collections).
      where("mrt_collections.ark = ?", @group.ark_id).
      order('last_add_version desc').
      includes(:mrt_versions, :mrt_version_metadata).
      paginate(:page       => (params[:page] || 1), 
               :per_page   => 10)
  end

  def search_results
    terms = Unicode.downcase(params[:terms]).gsub('%', '\%').gsub('_', '\_').split(/\s+/).delete_if{|t|t.blank?}
     terms_q = terms.map{|t| "%#{t}%" }
    @results = MrtObject.joins(:mrt_collections).
      where("mrt_collections.ark = ?", @group.ark_id).
      includes(:mrt_versions, :mrt_version_metadata).paginate(:page=>params[:page], :per_page=>10)
    terms_q.each do |q|
      @results = @results.where("mrt_objects.primary_id LIKE ? OR mrt_objects.local_id LIKE ? OR mrt_version_metadata.value LIKE ?", q, q, q)
    end
  end
end
