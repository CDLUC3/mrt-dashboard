require 'tempfile'

class ObjectController < ApplicationController
  include IngestMixin
  include MerrittRetryMixin

  before_action :require_user, except: %i[recent ingest update]
  before_action :require_named_user_or_401, only: %i[recent add]
  before_action :load_object, only: %i[index download download_user download_manifest presign object_info audit_replic]

  before_action(only: %i[download download_user download_manifest presign]) do
    unless current_user_can_download?(@object)
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_action(only: %i[ingest update]) do
    if current_user
      render(status: 404, plain: '') unless current_user.groups('write').any? { |g| g.submission_profile == params[:profile] }
    else
      render(status: 401, plain: '')
    end
  end

  protect_from_forgery except: %i[ingest update]

  def load_object
    merritt_retry_block('load_object') do
      res = InvObject.where('ark = ?', params_u(:object)).includes(:inv_collections, inv_versions: [:inv_files])
      @object = res.first unless res.empty?
    end

    raise ActiveRecord::RecordNotFound if @object.nil?
  end

  def ingest
    render(status: 400, plain: "Bad file parameter.\n") && return unless params[:file].respond_to?(:tempfile)

    do_post(APP_CONFIG['ingest_service'], ingest_params_from(params, current_user))
  end

  def update
    render(status: 400, plain: "Bad file parameter.\n") && return unless params[:file].respond_to?(:tempfile)

    do_post(APP_CONFIG['ingest_service_update'], update_params_from(params, current_user))
  end

  def index
    return if @object.user_has_read_permission?(current_uid)

    render(file: "#{Rails.root}/public/401.html", status: 401, layout: false) unless check_ark_redirects(@object.group)
  end

  def download
    render(file: "#{Rails.root}/public/403.html", status: 403, layout: false) && return if @object.exceeds_download_size?
    # this process used to trigger the large object email which has become obsolete with presigned urls
    render(file: "#{Rails.root}/public/413.html", status: 413, layout: false) && return if @object.exceeds_sync_size?

    stream_response("#{@object.bytestream_uri}?t=zip", 'attachment', "#{pairtree_encode(@object.ark)}_object.zip", 'application/zip')
  end

  def download_user # TODO: rename to downloadProducerFiles or similar
    stream_response("#{@object.bytestream_uri2}?t=zip", 'attachment', "#{pairtree_encode(@object.ark)}_object.zip", 'application/zip')
  end

  def download_manifest
    stream_response(@object.bytestream_uri3.to_s, 'attachment', pairtree_encode(@object.ark), 'text/xml')
  end

  # rubocop:disable Lint/RescueException
  def upload
    if params[:file].nil?
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to(controller: 'object', action: 'add', group: current_group) && return
    end

    begin
      post_upload
      redirect_to(controller: 'object', action: 'submitted', batch_id: @batch_id, obj_count: @obj_count)
    rescue Exception => e # TODO: should this be StandardError?
      render_upload_error(e)
    end
  end
  # rubocop:enable Lint/RescueException

  def submitted
    # :nocov:
    unless params[:batch_id] && params[:obj_count]
      render 404, plain: '404 Not Found'
      return
    end
    @batch_id = params[:batch_id]
    @obj_count = params[:obj_count]
    # :nocov:
  end

  def recent
    merritt_retry_block('recent (objcts)') do
      do_recent
    end
  end

  def do_recent
    @collection_ark = params[:collection]
    collection = InvCollection.where(ark: @collection_ark).first
    render(status: 404, plain: '404 Not Found') && return if collection.nil? || collection.to_s == ''

    return unless check_atom_group_permissions

    @objects = collection.recent_objects.paginate(paginate_args(500))
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def presign
    nk = {
      node_id: @object.node_number,
      key: ApplicationController.encode_storage_key(@object.ark)
    }
    presign_get_obj_by_node_key(nk, params)
  end

  def object_info
    maxfile = params.fetch(:maxfile, '2500').to_i.clamp(0, 2500)
    index = params.fetch(:index, '0').to_i

    return render status: 401, plain: '' unless @object.user_has_read_permission?(current_uid)

    info = @object.object_info(index: index, maxfile: maxfile)
    render status: 200, json: ObjectController.add_fixity_to_info(@object, info).to_json
  end

  def self.fixity_sql(object)
    %{
      select
        ifnull(concat(n.number, ' ', n.description), concat('node_id ', a.inv_node_id)) as node,
        a.status,
        count(distinct a.inv_file_id) as unique_file_count,
        count(a.id) as audit_count,
        min(a.verified) as earliest_verified,
        max(a.verified) as latest_verified
      from
        inv_objects o
      inner join
        inv_files f
        on f.inv_object_id = o.id and f.billable_size = f.full_size
      left join
        inv_audits a
        on o.id = a.inv_object_id
        and f.id = a.inv_file_id
      inner join
        inv_nodes n
        on n.id = a.inv_node_id
      where
        o.id = #{object.id}
      group by
        node,
        a.status
    }
  end

  def self.add_fixity_to_info(object, info)
    info[:fixity] = []
    # :nocov:
    if info['total_files'] > 40_000
      info[:fixity] << { message: 'This object has too many files to display fixity state.' }
      return info
    end
    ActiveRecord::Base.connection.execute(ObjectController.fixity_sql(object)).each do |row|
      info['unique_file_count'] = row[2]
      data = {
        node: row[0],
        status: row[1],
        audit_count: row[3],
        earliest_verified: row[4],
        latest_verified: row[5]
      }
      info[:fixity].push(data)
    end
    # :nocov:
    info
  end

  def audit_replic
    return render status: 401, plain: '' unless @object.user_has_read_permission?(current_uid)

    @datestr = 'INTERVAL -15 MINUTE'
    @count_by_status = @object.audit_replic_stats(@datestr)
  end

  def force_fail
    # :nocov:
    merritt_retry_block('force_fail') do
      raise StandardError, 'force fail'
    end
    # :nocov:
  end

  private

  def check_atom_group_permissions
    group = Group.find(params[:collection])
    render(status: 404, plain: '404 Not Found') && return unless group
    render(status: 401, plain: '401 Not Authorized') && return unless group.user_has_read_permission?(current_uid)

    true
  end

  def pairtree_encode(ark)
    Orchard::Pairtree.encode(ark.to_s)
  end

  def do_post(post_url, post_params)
    resp = http_post(post_url, post_params)
    render(status: resp.status, content_type: resp.headers[:content_type], body: resp.body)
  end

end
