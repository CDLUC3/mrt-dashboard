class CollectionController < ApplicationController
  NO_ACCESS = 'You do not have access to that collection'.freeze

  before_action :require_user
  before_action :require_request_group

  before_action do
    if !@request_group.user_has_read_permission?(current_uid) && !check_ark_redirects(@request_group)
      raise(ActiveResource::UnauthorizedAccess, NO_ACCESS)
    end
  end

  # Load the group specified in the params[:group]
  def require_request_group
    group = Group.find(params[:group])
    raise ActiveRecord::RecordNotFound unless group

    @request_group = group
  rescue LdapMixin::LdapException
    raise ActiveRecord::RecordNotFound
  end

  def object_count
    render partial: 'object_count'
  end

  def version_count
    render partial: 'version_count'
  end

  def file_count
    render partial: 'file_count'
  end

  def billable_size
    render partial: 'billable_size'
  end

  def index
    set_session_group(@request_group) unless params[:group] == session[:group_id]
    @recent_objects = find_all(@request_group.ark_id)
  end

  def search_results
    terms = parse_terms(params[:terms])
    collection_ark = @request_group.ark_id
    if terms.empty?
      @results = find_all(collection_ark)
    else
      term = params.fetch(:terms, '').strip
      @results = find_by_localid(collection_ark, term)
      @results = find_by_file_name(collection_ark, term) if @results.empty?
      @results = find_by_full_text(collection_ark, terms) if @results.empty?
    end
  end

  def local_id_search
    terms = parse_terms(params[:terms])
    collection_ark = @request_group.ark_id
    unless terms.empty?
      @results = find_by_localid(collection_ark, params[:terms])
      return render_object_info(@results[0].ark) if @results.length == 1
    end
    render status: 201, json: {}.to_json
  end

  private

  def render_object_info(ark)
    object = InvObject.where('ark = ?', ark).includes(:inv_collections, inv_versions: [:inv_files]).first
    render json: object.object_info.to_json, status: 200
  end

  def find_all(collection_ark)
    InvObject.joins(:inv_collections)
      .where('inv_collections.ark = ?', collection_ark)
      .order('inv_objects.modified desc')
      .includes(:inv_versions, :inv_dublinkernels)
      .quickloadhack
      .paginate(paginate_args)
  end

  def parse_terms(terms_param)
    terms = Unicode.downcase(terms_param)
      .split(/\s+/)
      .map { |t| is_ark?(t) ? t[11..] : t } # special ark handling
      .delete_if { |t| (t.blank? || t.size < 4) }
    terms[0..50] # we can't have more than 60 terms, so just drop > 50
  end

  def find_by_localid(collection_ark, term)
    InvObject
      .joins(:inv_collections, :inv_localids)
      .where('inv_collections.ark = ?', collection_ark)
      .where('inv_localids.local_id = ?', term)
      .includes(:inv_versions)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

  def find_by_file_name(collection_ark, term)
    InvObject
      .joins(:inv_collections, :inv_files)
      .where('inv_collections.ark = ?', collection_ark)
      .where('inv_files.pathname = ?', "producer/#{term}")
      .includes(:inv_versions)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

  def find_by_full_text(collection_ark, terms)
    # new, more efficient full text query (thanks Debra)
    where_clause = "(MATCH (sha_dublinkernels.value) AGAINST (\"#{terms.map { |_t| '? ' }.join}\"))"
    InvObject
      .joins(:inv_collections, inv_dublinkernels: :sha_dublinkernel)
      .where('inv_collections.ark = ?', collection_ark)
      .where(where_clause, *terms)
      .includes(:inv_versions, :inv_dublinkernels)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_session_group(group)
    session[:group_id]          = group.id
    session[:group_ark]         = group.ark_id
    session[:group_description] = group.description
  end
  # rubocop:enable Naming/AccessorMethodName
end
