class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_request_group

  # Load the group specified in the params[:group]
  def require_request_group
    @request_group = Group.find(params[:group])
  end

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
    # load the requested group into the session
    if (session[:group_id] != params[:group]) then
      session[:group_id] = @request_group.id
      session[:group_ark] = @request_group.ark_id
      session[:group_description] = @request_group.description
    end
    @recent_objects = InvObject.joins(:inv_collections).
      where("inv_collections.ark = ?", @request_group.ark_id).
      order('inv_objects.modified desc').
      includes(:inv_versions, :inv_dublinkernels).
      paginate(paginate_args)
  end

  def search_results
    terms = Unicode.downcase(params[:terms]).gsub('%', '\%').gsub('_', '\_').split(/\s+/).delete_if{|t|t.blank?}
    terms_q = terms.map{|t| "%#{t}%" }
    @results = InvObject.joins(:inv_collections).
      where("inv_collections.ark = ?", @request_group.ark_id).
      includes(:inv_versions, :inv_dublinkernels).paginate(paginate_args)
    terms_q.each do |q|
      @results = @results.where("inv_objects.ark LIKE ? OR inv_objects.erc_where LIKE ? OR inv_dublinkernels.value LIKE ?", q, q, q)
    end
  end
end
