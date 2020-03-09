require 'httpclient'
require 'json'

class FileController < ApplicationController
  before_filter :require_user

  # Do not force redirect to latest version for key lookup
  before_filter :redirect_to_latest_version, except: %i[storage_key]

  # Do not force load of file for key lookup
  before_filter :load_file, except: %i[storage_key]

  before_filter :check_download, except: %i[storage_key]

  before_filter :check_version, only: %i[download presign]

  def download
    if @file.exceeds_download_size?
      render file: "#{Rails.root}/public/403.html", status: 403, layout: false
    else
      stream_response(@file.bytestream_uri,
                      'inline',
                      File.basename(@file.pathname),
                      @file.mime_type,
                      @file.full_size)
    end
  end

  # API Call to redirect to presign URL for a file.
  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/ui/presign-file.md
  def presign
    nk = storage_key_do
    presigned = presign_get_by_node_key(nk)
    return unless response.status == 200
    url = presigned['url']
    response.headers['Location'] = url
    render status: 303, text: ''
  end

  # API to return the node id and key for a file within the storage service.
  def storage_key
    ret = storage_key_do
    render status: ret['status'], json: ret.to_json
  end

  # Construct a storage key from component parts
  def self.build_storage_key(ark, version, file)
    "#{ark}|#{version}|#{file}"
  end

  # Encode a storage key constructed from component parts
  def self.encode_storage_key(ark, version, file)
    key = FileController.build_storage_key(ark, version, file)
    Encoder.urlencode(key)
  end

  def self.get_storage_presign_url(obj)
    base = APP_CONFIG['storage_presign_file']
    return File.join(base, 'not-applicable') unless obj.key?(:node_id) && obj.key?(:key)
    File.join(
      APP_CONFIG['storage_presign_file'],
      obj[:node_id].to_s,
      obj[:key]
    )
  end

  private

  def check_download
    return if current_user_can_download?(@file.inv_version.inv_object)
    flash[:error] = 'You do not have download permissions.'
    render file: "#{Rails.root}/public/401.html", status: 401, layout: false
  end

  def check_version
    version = @file.inv_version
    obj = version.inv_object
    check_dua(obj, { object: obj, version: version, file: @file })
  end

  # Perform database lookup for storge node and key
  # rubocop:disable all
  def storage_key_do
    version = params_u(:version).to_i
    ark = params_u(:object)
    pathname = params_u(:file)

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
    ret = {status: 404, message: 'Not found'}
    sql += " ORDER BY v.number DESC limit 1"
    sql2 += " ORDER BY v.number DESC limit 1"

    if version == 0
      results = ActiveRecord::Base
        .connection
        .raw_connection
        .prepare(sql)
        .execute(ark, pathname)
    else
      results = ActiveRecord::Base
        .connection
        .raw_connection
        .prepare(sql2)
        .execute(ark, pathname, version, version)
    end

    if results.present?
      results.each do |row|
        ret = {
          status: 200,
          message: '',
          node_id: row[0],
          key: FileController.encode_storage_key(ark, row[1], pathname)
        }
      end
    end

    # For debugging, show url in thre return object
    ret[:url] = FileController.get_storage_presign_url(ret.with_indifferent_access)
    ret.with_indifferent_access
  end
  # rubocop:enable all

  def load_file
    filename = params_u(:file)

    # determine if user is retrieving a system file; otherwise assume
    # they are obtaining a producer file which needs to prepended to
    # the filename
    filename = "producer/#{filename}" unless filename =~ /^(producer|system)/

    @file = InvFile.joins(:inv_version, :inv_object)
      .where('inv_objects.ark = ?', params_u(:object))
      .where('inv_versions.number = ?', params[:version])
      .where('inv_files.pathname = ?', filename)
      .first
    raise ActiveRecord::RecordNotFound if @file.nil?
  end

  # Call storage service to create a presigned URL for a file
  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/storage/presign-file.md
  def presign_get_by_node_key(obj)
    r = HTTPClient.new.get(
      FileController.get_storage_presign_url(obj),
      {},
      {},
      follow_redirect: true
    )
    eval_presign_get_by_node_key(r)
  end

  # Evaluate response from the storage service presign request
  # If 409 is returned, redirect to the traditional file download
  def eval_presign_get_by_node_key(r)
    if r.status == 409
      download_response
    elsif r.status == 200
      JSON.parse(r.content).with_indifferent_access
    else
      json = JSON.parse(r.content).with_indifferent_access
      render status: r.status, json: json
    end
  end

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
