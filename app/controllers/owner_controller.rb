class OwnerController < ApplicationController
  NO_ACCESS = 'You do not have access to that owner'.freeze

  before_action :require_user
  before_action :require_request_owner

  def find(name)
    InvOwner
      .where('name = ?', name)
      .first
  end

  before_action do
    raise(ActiveResource::UnauthorizedAccess, NO_ACCESS) unless access?
  end

  # if this solution is generalized, a new LDAP attribute should be set at a user level to enable owner search
  # for the initial implementation, access will be restricted to selected userids
  def access?
    return false if @request_owner.nil?

    @request_owner.name == current_owner_name
  end

  # Load the group specified in the params[:group]
  def require_request_owner
    owner = find(params[:owner])

    raise ActiveRecord::RecordNotFound if owner.nil?

    @request_owner = owner
    puts @request_owner.ark
  end

  def index
    @recent_objects = find_none
  end

  def search_results
    terms = parse_terms(params[:terms])
    if terms.empty?
      @results = find_none
    else
      @results = find_by_localid(@request_owner, params[:terms])
      @results = find_by_file_name(@request_owner, params[:terms]) if @results.empty?
      @results = find_by_full_text(@request_owner, terms) if @results.empty?
    end
  end

  private

  def render_object_info(ark)
    object = InvObject.where('ark = ?', ark).includes(:inv_collections, inv_versions: [:inv_files]).first
    render json: object.object_info.to_json, status: 200
  end

  def parse_terms(terms_param)
    terms = Unicode.downcase(terms_param)
      .split(/\s+/)
      .map { |t| is_ark?(t) ? t[11..] : t } # special ark handling
      .delete_if { |t| (t.blank? || t.size < 4) }
    terms[0..50] # we can't have more than 60 terms, so just drop > 50
  end

  def find_none
    InvObject
      .where('inv_objects.id = -1')
      .includes(:inv_versions)
      .quickloadhack
      .paginate(paginate_args)
  end

  def find_by_localid(owner, term)
    InvObject
      .joins(:inv_owner, :inv_localids)
      .where('inv_owners.ark = ?', owner.ark)
      .where('inv_localids.local_id = ?', term)
      .includes(:inv_versions)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

  def find_by_file_name(owner, term)
    InvObject
      .joins(:inv_owner, :inv_files)
      .where('inv_owners.ark = ?', owner.ark)
      .where('inv_files.pathname = ?', "producer/#{term}")
      .includes(:inv_versions)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

  def find_by_full_text(owner, terms)
    where_clause = "(MATCH (sha_dublinkernels.value) AGAINST (\"#{terms.map { |_t| '? ' }.join}\"))"
    InvObject
      .joins(:inv_owner, inv_dublinkernels: :sha_dublinkernel)
      .where('inv_owners.ark = ?', owner.ark)
      .where(where_clause, *terms)
      .includes(:inv_versions, :inv_dublinkernels)
      .quickloadhack
      .limit(10)
      .distinct
      .paginate(paginate_args)
  end

end
