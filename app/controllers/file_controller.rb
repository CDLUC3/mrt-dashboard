require 'httpclient'
require 'json'

class FileController < ApplicationController
  before_filter do
    require_user
  end

  # Do not force redirect to latest version for key lookup
  before_filter(except: %i[storage_key]) do
    redirect_to_latest_version
  end

  # Do not force load of file for key lookup
  before_filter(except: %i[storage_key]) do
    load_file
  end

  before_filter(except: %i[storage_key]) do
    unless current_user_can_download?(@file.inv_version.inv_object)
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: %i[download presign]) do
    version = @file.inv_version
    obj = version.inv_object
    check_dua(obj, { object: obj, version: version, file: @file })
  end

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

  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/ui/presign-file.md
  def presign
    nk = storage_key_do
    presigned = presign_get_by_node_key(nk)
    return unless response.status == 200
    url = presigned['url']
    response.headers['Location'] = url
    render status: 303, text: ''
  end

  def storage_key
    ret = storage_key_do
    render status: ret['status'], json: ret.to_json
  end

  def self.build_storage_key(ark, version, file)
    "#{ark}|#{version}|#{file}"
  end

  def self.encode_storage_key(ark, version, file)
    ERB::Util.url_encode(FileController.build_storage_key(ark, version, file))
  end

  def self.get_storage_presign_url(obj)
    # Note - assume the config variable contains a slash...do not duplicate the slash
    "#{APP_CONFIG['storage_presign_file']}#{obj[:node_id]}/#{obj[:key]}"
  end

  private

  # rubocop:disable all
  def storage_key_do
    version = params_u(:version).to_i
    ark = params_u(:object)
    pathname = params_u(:file)

    sql = %{
      SELECT
        n.NUMBER AS node,
        n.logical_volume,
        o.version_number,
        o.md5_3,
        f.billable_size,
        v.ark,
        v.NUMBER AS key_version,
        f.pathname
      FROM
        inv_versions AS v,
        inv_nodes_inv_objects AS NO,
        inv_nodes AS n,
        inv_files AS f,
        inv_objects AS o
      WHERE
        v.ark = ?
        #if version is > 0
        AND f.pathname = ?
        AND o.id = v.inv_object_id
        AND NO.role = 'primary'
        AND f.inv_version_id = v.id
        AND NO.inv_object_id = v.inv_object_id
        AND n.id = NO.inv_node_id
        AND f.billable_size > 0
    }
    sql2 = sql + ' AND v.number = ?'
    ret = {status: 404, message: 'Not found'}

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
        .execute(ark, pathname, version)
    end

    if results.present?
      results.each do |row|
        ret = {
          status: 200,
          message: '',
          node_id: row[0],
          key: FileController.encode_storage_key(row[5], row[6], row[7])
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

  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/storage/presign-file.md
  def presign_get_by_node_key(obj)
    r = HTTPClient.new.get(
      FileController.get_storage_presign_url(obj),
      {},
      {}
    )
    eval_presign_get_by_node_key(r)
  end

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

  def download_response
    {
      url: external_download_url
    }.with_indifferent_access
  end

  def external_download_url
    @file.external_bytestream_uri.to_s
  end

end
