class VersionController < ApplicationController
  before_filter :require_user
  before_filter :redirect_to_latest_version
  before_filter :load_version

  before_filter(:only => [:download, :downloadUser]) do
    if (!has_object_permission?(@version.inv_object, 'download')) then
      flash[:error] = "You do not have download permissions."
      redirect_to(:action  => :index,
                  :object  => @version.inv_object,
                  :version => @version) and return false
    end
  end

  before_filter(:only => [:download, :downloadUser]) do
    check_dua(@version.inv_object,
              { :object  => @version.inv_object,
                :version => @version})
  end

  before_filter(:only => [:download, :downloadUser]) do
    # if size is > 4GB, redirect to have user enter email for asynch
    # compression (skipping streaming)
    if exceeds_size(@version.inv_object) then
      redirect_to(:controller => "lostorage", 
                  :action     => "index", 
                  :object     => @version.inv_object, 
                  :version    => @version) and return
    end
  end

  def load_version
    @version = InvVersion.joins(:inv_object).
      where("inv_objects.ark = ?", params_u(:object)).
      where("inv_versions.number = ?", params_u(:version).to_i).
      includes(:inv_dublinkernels, :inv_object => [:inv_versions]).
      first
    raise ActiveRecord::RecordNotFound if @version.nil?
  end

  def index
  end

  def download
    stream_response("#{@version.bytestream_uri}?t=zip",
                    "attachment",
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    "application/zip")
  end

  def downloadUser
    stream_response("#{@version.bytestream_uri2}?t=zip",
                    "attachment",
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    "application/zip")
  end
end
