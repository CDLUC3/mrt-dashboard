class VersionController < ApplicationController
  before_filter :require_user
  before_filter :redirect_to_latest_version
  before_filter :load_version

  before_filter(only: %i[download download_user async]) do
    unless has_object_permission?(@version.inv_object, 'download')
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: %i[download download_user]) do
    obj = @version.inv_object
    check_dua( obj, { object: obj, version: @version } )
  end

  before_filter(only: %i[download download_user]) do
    if exceeds_download_size_version(@version)
      render file: "#{Rails.root}/public/403.html", status: 403, layout: false
    elsif exceeds_sync_size_version(@version)
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

  def index; end

  def async
    if exceeds_download_size_version(@version)
      render nothing: true, status: 403
    elsif exceeds_sync_size_version(@version)
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
end
