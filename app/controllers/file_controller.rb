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

  before_filter(only: [:download, :presign]) do
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

  def presign
    node_key = presign_node_key()
    response = presign_get_by_node_key(node_key)
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

  def presign_node_key
    version = @file.inv_version
    obj = version.inv_object
    node_key_str = HTTPClient.new.get_content(
                  APP_CONFIG['inventory_presign_file'],
                  { object: obj.ark, version: version.number, file: @file.pathname },
                  { 'Accept' => 'application/json' })
    node_key = JSON.parse(node_key_str)
    puts(node_key)
    node_key
  end

  def presign_get_by_node_key(node_key)
    response = HTTPClient.new.get(
            APP_CONFIG['storage_presign_file'],
            query = { node: node_key['node_id'], key: node_key['key'] },
            extheader = { 'Accept' => 'application/json' })
    puts(response)
    response
  end
end
