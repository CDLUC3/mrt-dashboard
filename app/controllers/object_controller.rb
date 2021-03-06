require 'tempfile'

class ObjectController < ApplicationController
  include MintMixin
  include IngestMixin

  before_action :require_user, except: %i[jupload_add recent ingest mint update]
  before_action :load_object, only: %i[index download download_user download_manifest presign]

  before_action(only: %i[download download_user download_manifest presign]) do
    unless current_user_can_download?(@object)
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_action(only: %i[download download_user]) do
    check_dua(@object, { object: @object })
  end

  before_action(only: %i[ingest mint update]) do
    if current_user
      render(status: 404, plain: '') unless current_user.groups('write').any? { |g| g.submission_profile == params[:profile] }
    else
      render(status: 401, plain: '')
    end
  end

  protect_from_forgery except: %i[ingest mint update]

  def load_object
    @object = InvObject.where('ark = ?', params_u(:object)).includes(:inv_collections, inv_versions: [:inv_files]).first
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

  def mint
    do_post(APP_CONFIG['mint_service'], mint_params_from(params))
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
    rescue Exception => e # TODO: should this be StandardError?
      render_upload_error(e)
    end
  end
  # rubocop:enable Lint/RescueException

  def recent
    @collection_ark = params[:collection]
    collection = InvCollection.where(ark: @collection_ark).first
    render(status: 404, plain: '404 Not Found') && return if collection.nil? || collection.to_s == ''

    @objects = collection.recent_objects.paginate(paginate_args)
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

  private

  def pairtree_encode(ark)
    Orchard::Pairtree.encode(ark.to_s)
  end

  def do_post(post_url, post_params)
    resp = http_post(post_url, post_params)
    render(status: resp.status, content_type: resp.headers[:content_type], body: resp.body)
  end

end
