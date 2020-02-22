require 'httpclient'
require 'json'

class FileController < ApplicationController
  before_filter :require_user
  before_filter :redirect_to_latest_version
  before_filter :load_file

  before_filter do
    unless current_user_can_download?(@file.inv_version.inv_object)
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: %i[download presign storage_key]) do
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
    # The following are private methods... can I invoke rspec tests on these methods?
    node_key = presign_node_key
    return unless response.status == 200
    presigned = presign_get_by_node_key(node_key)
    return unless response.status == 200
    url = presigned['url']
    response.headers['Location'] = url
    render status: 303, text: ''
  end

  # rubocop:disable all
  def storage_key
    version = @file.inv_version
    obj = version.inv_object
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
    sql2 = sql + ' AND v.number <= ?'
    ret = {status: 404, message: 'Not found'}
    if version.number == 0
      results = ActiveRecord::Base
        .connection
        .raw_connection
        .prepare(sql)
        .execute(version.ark, @file.pathname)
    else
      results = ActiveRecord::Base
        .connection
        .raw_connection
        .prepare(sql2)
        .execute(version.ark, @file.pathname, version.number)
    end

    if results.present?
      results.each do |row|
        ret = {
          status: 200,
          message: '',
          node_id: row[1],
          key: row[5] + '|' + row[6].to_s + '|' + row[7]
        }
      end
    end
    render ret['status'], json: ret.to_json
  end
  # rubocop:enable all

  private

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

  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/inventory/presign-file.md
  def presign_node_key
    version = @file.inv_version
    obj = version.inv_object
    r = HTTPClient.new.get(
      APP_CONFIG['get_storage_key_file'],
      { object: obj.ark, version: version.number, file: @file.pathname },
      { 'Accept' => 'application/json' }
    )
    eval_presign_node_key(r)
  end

  def eval_presign_node_key(r)
    if r.status == 200
      JSON.parse(r.content)
    else
      json = JSON.parse(r.content).with_indifferent_access
      render status: r.status, json: json
    end
  end

  # https://github.com/CDLUC3/mrt-doc/blob/master/endopoints/storage/presign-file.md
  def presign_get_by_node_key(node_key)
    r = HTTPClient.new.get(
      APP_CONFIG['storage_presign_file'],
      node_key_params(node_key),
      { 'Accept' => 'application/json' }
    )
    eval_presign_get_by_node_key(r)
  end

  def node_key_params(n)
    { node: n['node_id'], key: n['key'] }.with_indifferent_access
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
      url: download_url
    }.with_indifferent_access
  end

  def download_url
    @file.bytestream_uri.to_s
  end

end
