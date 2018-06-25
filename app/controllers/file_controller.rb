class FileController < ApplicationController
  before_filter :require_user
  before_filter :redirect_to_latest_version
  before_filter :load_file

  before_filter do
    unless has_object_permission?(@file.inv_version.inv_object, 'download')
      flash[:error] = 'You do not have download permissions.'
      render file: "#{Rails.root}/public/401.html", status: 401, layout: false
    end
  end

  before_filter(only: [:download]) do
    #:nocov:
    check_dua(@file.inv_version.inv_object,
              { object: @file.inv_version.inv_object,
                version: @file.inv_version,
                file: @file })
    #:nocov:
  end

  def download
    if exceeds_download_size_file(@file)
      render file: "#{Rails.root}/public/403.html", status: 403, layout: false
    else
      stream_response(@file.bytestream_uri,
                      'inline',
                      File.basename(@file.pathname),
                      @file.mime_type,
                      @file.full_size)
    end
  end

  private
  def load_file
    filename = params_u(:file)

    # determine if user is retrieving a system file; otherwise assume
    # they are obtaining a producer file which needs to prepended to
    # the filename
    filename = "producer/#{filename}" unless filename.match(/^(producer|system)/)

    @file = InvFile.joins(:inv_version, :inv_object)
      .where('inv_objects.ark = ?', params_u(:object))
      .where('inv_versions.number = ?', params[:version])
      .where('inv_files.pathname = ?', filename)
      .first
    raise ActiveRecord::RecordNotFound if @file.nil?
  end
end
