require 'httpclient'
require 'json'

class FileController < ApplicationController
  include MerrittRetryMixin

  before_action :require_user

  before_action :fix_params

  # Do not force redirect to latest version for key lookup
  before_action :redirect_to_latest_version, except: %i[storage_key]

  # Do not force load of file for key lookup
  before_action :load_file, except: %i[storage_key]

  before_action :check_download, except: %i[storage_key]

  def download
    # deprecate file download in favor of presigned retrieval
    url = request.url.gsub(%r{/d/}, '/api/presign-file/')
    response.headers['Location'] = url
    render status: 308, plain: ''
  end

  # API Call to redirect to presign URL for a file.
  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/ui/presign-file.md
  def presign
    nk = storage_key_do
    presigned = presign_get_by_node_key(nk, params)
    return unless response.status == 200

    if params.key?(:no_redirect)
      render status: 200, json: presigned.to_json
      return
    end
    url = presigned['url']
    response.headers['Location'] = url
    render status: 303, plain: ''
  end

  # API to return the node id and key for a file within the storage service.
  def storage_key
    ret = storage_key_do
    render status: ret['status'], json: ret.to_json
  end

  private

  def check_download
    merritt_retry_block('check_download') do
      obj = @file.inv_version.inv_object
      return if current_user_can_download?(obj)
    end

    flash[:error] = 'You do not have download permissions.'
    render file: "#{Rails.root}/public/401.html", status: 401, layout: false
  end

  def not_found_obj
    {
      status: 404,
      message: 'Not found'
    }
  end

  def storage_key_do
    merritt_retry_block('storage_key_do') do
      do_storage_key_do
    end
  end

  # Perform database lookup for storge node and key
  # rubocop:disable all
  def do_storage_key_do
    version = params_u(:version).to_i
    ark = params_u(:object)
    pathname = fix_filename

    sql = %{
      SELECT
        n.NUMBER AS node,
        v.number
      FROM
        inv_nodes AS n
      INNER JOIN inv_nodes_inv_objects NO
        ON n.id = NO.inv_node_id
          and NO.role = 'primary'
      INNER JOIN inv_objects o
        ON NO.inv_object_id = o.id
      INNER JOIN inv_versions v
        ON v.inv_object_id = o.id
      INNER JOIN inv_files f
        ON f.inv_version_id = v.id
          AND f.billable_size > 0
      WHERE
        o.ark = ?
        AND f.pathname = ?
        AND md5(f.pathname) = md5(?)
    }
    sql2 = sql + %{
      AND v.number <= ?
      AND EXISTS (
        SELECT 1
        FROM inv_versions iv
        WHERE
          iv.inv_object_id = o.id
        AND
          iv.number = ?
      )
    }
    ret = not_found_obj
    sql += " ORDER BY v.number DESC limit 1"
    sql2 += " ORDER BY v.number DESC limit 1"

    if version == 0
      results = ApplicationRecord
        .connection
        .raw_connection
        .prepare(sql)
        .execute(ark, pathname, pathname)
    else
      results = ApplicationRecord
        .connection
        .raw_connection
        .prepare(sql2)
        .execute(ark, pathname, pathname, version, version)
    end

    if results.present?
      results.each do |row|
        ret = {
          status: 200,
          message: '',
          node_id: row[0],
          key: ApplicationController.encode_storage_key(ark, row[1], pathname)
        }
      end
    end

    # For debugging, show url in thre return object
    url = ApplicationController.get_storage_presign_url(ret.with_indifferent_access, has_file: true)
    ret[:url] = url unless url.nil?
    ret.with_indifferent_access
  end
  # rubocop:enable all

  def fix_filename
    # determine if the filename has already been decoded (by looking for the slash after producer or system)
    fname = params[:file]
    return fname if fname.match(%r{(producer|system)/})

    # retrieve decoded version of the parameter
    fname = params_u(:file)
    return fname if fname.valid_encoding?

    # :nocov:
    log.warn("invalid encoding for filname #{fname}")
    fname
    # :nocov:
  end

  def fix_params
    object_ark = params_u(:object)
    ver = params[:version]
    fname = fix_filename
    match_params("#{object_ark}/#{ver}/#{fname}")
  end

  def match_params(combine)
    return unless combine.valid_encoding?

    m = %r{^(ark:/\d+/[a-z0-9_]+)/(\d+)/(.*)$}.match(combine)
    replace_params(m) if m
  end

  def replace_params(match)
    params[:object] = match[1]
    params[:version] = match[2]
    params[:file] = match[3]
  end

  def load_file
    filename = fix_filename

    # determine if user is retrieving a system file; otherwise assume
    # they are obtaining a producer file which needs to prepended to
    # the filename
    filename = "producer/#{filename}" if filename.valid_encoding? && filename !~ /^(producer|system)/

    merritt_retry_block('load_file') do
      @file = InvFile.joins(:inv_version, :inv_object)
        .where('inv_objects.ark = ?', params_u(:object))
        .where('inv_versions.number = ?', params[:version])
        .where('inv_files.pathname = ?', filename)
        .first
      raise ActiveRecord::RecordNotFound if @file.nil?
    end
  end

  # Call storage service to create a presigned URL for a file
  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/storage/presign-file.md
  def presign_get_by_node_key(nodekey, params)
    merritt_retry_block('presign_get_by_node_key') do
      p = { contentType: @file.mime_type == 'text/plain' ? 'text/plain; charset=UTF-8' : @file.mime_type }
      p[:contentDisposition] = params[:contentDisposition] if params.key?(:contentDisposition)
      r = create_http_cli(connect: 15, receive: 15, send: 15).get(
        ApplicationController.get_storage_presign_url(nodekey, has_file: true),
        p, {}, follow_redirect: true
      )
      eval_presign_get_by_node_key(r)
    end
  rescue RetryException => e
    render status: e.status, plain: 'Failure in spite of retry'
  end

  # Evaluate response from the storage service presign request
  # If 409 is returned, redirect to the traditional file download
  # rubocop:disable all
  def eval_presign_get_by_node_key(r)
    if r.status == 409
      download_response
    elsif r.status == 200
      JSON.parse(r.content).with_indifferent_access
    elsif r.status == 404
      render file: "#{Rails.root}/public/404.html", status: 404, layout: nil
    else
      render file: "#{Rails.root}/public/500.html", status: r.status, layout: nil
    end
  end
  # rubocop:enable all

  # Return download URL as if it were a presigned URL
  def download_response
    {
      url: external_download_url
    }.with_indifferent_access
  end

  # Construct outward-facing download URL
  def external_download_url
    @file.external_bytestream_uri.to_s
  end

end
