require 'tempfile'

class ObjectController < ApplicationController
  include IngestMixin

  before_filter :require_user, except: %i[jupload_add recent ingest mint update]
  before_filter :load_object, only: %i[index download download_user download_manifest async]
  before_filter(only: %i[download download_user download_manifest async]) do
    unless has_object_permission?(@object, 'download')
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: [:index]) do
    render file: "#{Rails.root}/public/401.html", status: 401, layout: false unless has_object_permission_no_embargo?(@object, 'read')
  end

  before_filter(only: %i[download download_user]) do
    #:nocov:
    check_dua(@object, { object: @object })
    #:nocov:
  end

  before_filter(only: [:download]) do
    # Interactive large object download does not support userFriendly
    # Call controller directly

    if exceeds_download_size(@object)
      render file: "#{Rails.root}/public/403.html", status: 403, layout: false
    elsif exceeds_sync_size(@object)
      # if size is > max_archive_size, redirect to have user enter email for asynch compression (skipping streaming)
      redirect_to(controller: 'lostorage', action: 'index', object: @object)
    end
  end

  protect_from_forgery except: %i[ingest mint update]

  def load_object
    @object = InvObject.where('ark = ?', params_u(:object)).includes(:inv_collections, inv_versions: [:inv_files]).first
    raise ActiveRecord::RecordNotFound if @object.nil?
  end

  def ingest
    render(status: 401, text: '') && return unless current_user
    render(status: 404, text: '') && return unless user_can_write_to_profile?
    render(status: 400, text: "Bad file parameter.\n") && return unless params[:file].respond_to? :tempfile

    resp = mk_httpclient.post(
      APP_CONFIG['ingest_service'],
      ingest_params_from(params, current_user),
      { 'Content-Type' => 'multipart/form-data' }
    )
    render status: resp.status, content_type: resp.headers[:content_type], text: resp.body
  end

  def update
    render(status: 401, text: '') && return unless current_user
    render(status: 404, text: '') && return unless user_can_write_to_profile?
    render(status: 400, text: "Bad file parameter.\n") && return unless params[:file].respond_to? :tempfile

    resp = mk_httpclient.post(
      APP_CONFIG['ingest_service_update'],
      update_params_from(params, current_user),
      { 'Content-Type' => 'multipart/form-data' }
    )
    render status: resp.status, content_type: resp.headers[:content_type], text: resp.body
  end

  def mint
    render(status: 401, text: '') && return unless current_user
    render(status: 404, text: '') && return unless user_can_write_to_profile?

    resp = mk_httpclient.post(
      APP_CONFIG['mint_service'],
      mint_params_from(params),
      { 'Content-Type' => 'multipart/form-data' }
    )
    render status: resp.status, content_type: resp.headers[:content_type], text: resp.body
  end

  def index; end

  def download
    stream_response("#{@object.bytestream_uri}?t=zip",
                    'attachment',
                    "#{Orchard::Pairtree.encode(@object.ark.to_s)}_object.zip",
                    'application/zip')
  end

  def download_user # TODO: rename to downloadProducerFiles or similar
    stream_response("#{@object.bytestream_uri2}?t=zip",
                    'attachment',
                    "#{Orchard::Pairtree.encode(@object.ark.to_s)}_object.zip",
                    'application/zip')
  end

  def download_manifest
    stream_response(@object.bytestream_uri3.to_s,
                    'attachment',
                    Orchard::Pairtree.encode(@object.ark.to_s).to_s,
                    'text/xml')
  end

  def async # TODO: rename to requestAsyncDownload or something
    if exceeds_download_size(@object)
      render nothing: true, status: 403
    elsif exceeds_sync_size(@object)
      # Async Supported
      render nothing: true, status: 200
    else
      # Async Not Acceptable
      render nothing: true, status: 406
    end
  end

  # rubocop:disable Lint/RescueException
  def upload
    if params[:file].nil?
      flash[:error] = 'You must choose a filename to submit.'
      redirect_to(controller: 'object', action: 'add', group: current_group) && (return false)
    end
    begin
      post_upload
    rescue Exception => ex # TODO: should this be StandardError?
      # see if we can parse the error from ingest, if not then unknown error
      render_upload_error(ex)
    end
  end
  # rubocop:enable Lint/RescueException

  def recent
    @collection_ark = params[:collection]

    # prevent stack trace when collection does not exist
    c = InvCollection.where(ark: @collection_ark).first
    render(status: 404, text: '404 Not Found') && return if c.nil? || c.to_s == ''
    @objects = c.recent_objects.paginate(paginate_args)
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  def mint_params_from(params)
    {
      'profile'      => params[:profile],
      'erc'          => params[:erc],
      'file'         => Tempfile.new('restclientbug'),
      'responseForm' => params[:responseForm]
    }.reject { |_k, v| v.blank? }
  end

  # rubocop:disable Metrics/AbcSize
  def render_upload_error(ex)
    raise unless ex.respond_to?(:response)
    @doc = Nokogiri::XML(ex.response) { |config| config.strict.noent.noblanks }
    @description = "ingest: #{@doc.xpath('//exc:statusDescription')[0].child.text}"
    @error       = "ingest: #{@doc.xpath('//exc:error')[0].child.text}"
    render action: 'upload_error'
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def post_upload
    ingest_params = upload_params_from(params, current_user, current_group)
    resp          = mk_httpclient.post(APP_CONFIG['ingest_service_update'], ingest_params)
    @doc          = Nokogiri::XML(resp.content) { |config| config.strict.noent.noblanks }
    @batch_id     = @doc.xpath('//bat:batchState/bat:batchID')[0].child.text
    @obj_count    = @doc.xpath('//bat:batchState/bat:jobStates').length
  end
  # rubocop:enable Metrics/AbcSize

  def user_can_write_to_profile?
    current_user && current_user.groups('write').any? { |g| g.submission_profile == params[:profile] }
  end

  def mk_httpclient
    client = HTTPClient.new
    client.receive_timeout = 7200
    client.send_timeout = 3600
    client.connect_timeout = 7200
    client.keep_alive_timeout = 3600
    client
  end
end
