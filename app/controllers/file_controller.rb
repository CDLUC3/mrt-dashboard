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

  def storage_key
    sql = %{
SELECT user, name
FROM users
WHERE users.id = ?
LIMIT ?
}
    sql = "select count(*) from inv_files"
    results = ActiveRecord::Base.connection.exec_query(sql)
    return nil unless results.present?
    render status: 200, text: 'foo'
  end

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
