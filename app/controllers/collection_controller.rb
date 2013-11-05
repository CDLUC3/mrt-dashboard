class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  prepend_before_filter :set_group_session_via_group, :only => [:index, :search_results]

  def object_count
    render :partial=>"object_count"
  end

  def version_count
    render :partial=>"version_count"
  end

  def file_count
    render :partial=>"file_count"
  end

  def total_size
    render :partial=>"total_size"
  end
  
  def index
    #redirect objects to the object controller
    unless params[:object].nil? 
      redirect_to :controller=>'object', :action=>'index', :group=>params[:group], :object=>params[:object]
    end

    @recent_objects = InvObject.joins(:inv_collections).
      where("inv_collections.ark = ?", @group.ark_id).
      order('version_number desc').
      includes(:inv_versions, :inv_dublinkernels).
      paginate(:page       => (params[:page] || 1), 
               :per_page   => 10)
  end

  def search_results
    terms = Unicode.downcase(params[:terms]).gsub('%', '\%').gsub('_', '\_').split(/\s+/).delete_if{|t|t.blank?}
     terms_q = terms.map{|t| "%#{t}%" }
    @results = InvObject.joins(:inv_collections).
      where("inv_collections.ark = ?", @group.ark_id).
      includes(:inv_versions, :inv_dublinkernels).paginate(:page=>params[:page], :per_page=>10)
    terms_q.each do |q|
      @results = @results.where("inv_objects.ark LIKE ? OR inv_objects.erc_where LIKE ? OR inv_dublinkernels.value LIKE ?", q, q, q)
    end
  end
end
