class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_request_group

  before_filter do
    if (!has_group_permission?(@request_group, 'read')) then
      raise ActiveResource::UnauthorizedAccess.new('You do not have access to that collection')
    end
  end

  # Load the group specified in the params[:group]
  def require_request_group
    begin
      @request_group = Group.find(params[:group])
    rescue LdapMixin::LdapException 
      raise ActiveRecord::RecordNotFound
    end
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

  def total_size
    render partial: 'total_size'
  end

  def index
    # load the requested group into the session
    if (session[:group_id] != params[:group]) then
      session[:group_id] = @request_group.id
      session[:group_ark] = @request_group.ark_id
      session[:group_description] = @request_group.description
    end
    @recent_objects = InvObject.joins(:inv_collections).
      where('inv_collections.ark = ?', @request_group.ark_id).
      order('inv_objects.modified desc').
      includes(:inv_versions, :inv_dublinkernels).
      quickloadhack.
      paginate(paginate_args)
  end

  def search_results
    terms = Unicode.downcase(params[:terms]).
      split(/\s+/).
      map { |t| # special ark handling
        if is_ark?(t) then t[11..-1] else t end
      }.delete_if { |t| 
        (t.blank? || t.size < 4) # sql search doesn't work with terms less than 4 characters long
      }
    terms = terms[0..50] # we can't have more than 60 terms, so just drop > 50

    if terms.size == 0 then
      # no real search, just display 
      @results = InvObject.joins(:inv_collections).
        where('inv_collections.ark = ?', @request_group.ark_id).
        order('inv_objects.modified desc').
        includes(:inv_versions, :inv_dublinkernels).
        quickloadhack.
        paginate(paginate_args)
    else
      # new, more efficient full text query (thanks Debra)
      tb_count = 0
      where_clauses = terms.map {|t|
	'? '
      }
      where_clause = '(MATCH (sha_dublinkernels.value) AGAINST ("' + where_clauses.join('') + '"))'

      ark_id = @request_group.ark_id
      @results = InvObject.
        joins(:inv_collections, inv_dublinkernels: :sha_dublinkernel).
        where('inv_collections.ark = ?', ark_id).
        where(where_clause, *terms).
        includes(:inv_versions, :inv_dublinkernels).
        quickloadhack.
        limit(10).
        uniq.
        paginate(paginate_args)
    end
  end
end
