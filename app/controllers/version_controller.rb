class VersionController < ApplicationController
  before_filter :require_user
  before_filter :redirect_to_latest_version
  before_filter :load_version

  before_filter(only: %i[download download_user async presign]) do
    unless current_user_can_download?(@version.inv_object)
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: %i[download download_user presign]) do
    obj = @version.inv_object
    check_dua(obj, { object: obj, version: @version })
  end

  before_filter(only: %i[download download_user]) do
    if @version.exceeds_download_size?
      render file: "#{Rails.root}/public/403.html", status: 403, layout: false
    elsif @version.exceeds_sync_size?
      # if size is > max_archive_size, redirect to have user enter email for asynch
      # compression (skipping streaming)
      redirect_to(controller: 'lostorage',
                  action: 'index',
                  object: @version.inv_object,
                  version: @version)
    end
  end

  def load_version
    @version = InvVersion.joins(:inv_object)
      .where('inv_objects.ark = ?', params_u(:object))
      .where('inv_versions.number = ?', params_u(:version).to_i)
      .includes(:inv_dublinkernels, inv_object: [:inv_versions])
      .first
    raise ActiveRecord::RecordNotFound if @version.nil?
  end

  def index
    render(file: "#{Rails.root}/public/401.html", status: 401, layout: false) unless @version.inv_object.user_has_read_permission?(current_uid)
  end

  def async
    if @version.exceeds_download_size?
      render nothing: true, status: 403
    elsif @version.exceeds_sync_size?
      # Async Supported
      render nothing: true, status: 200
    else
      # Async Not Acceptable
      render nothing: true, status: 406
    end
  end

  def download
    stream_response("#{@version.bytestream_uri}?t=zip",
                    'attachment',
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    'application/zip')
  end

  def download_user
    stream_response("#{@version.bytestream_uri2}?t=zip",
                    'attachment',
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    'application/zip')
  end

  def presign
    obj = @version.inv_object
    nk = {
      node_id: obj.node_number,
      key: ApplicationController.encode_storage_key(obj.ark, @version.number)
    }
    presign_get_obj_by_node_key(nk, params)
  end

end
