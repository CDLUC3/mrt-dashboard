class VersionController < ApplicationController
  before_filter :require_user
  before_filter :load_version
  before_filter(:only => [:download]) do
    if (!has_object_permission?(@version.inv_object, 'download')) then
      flash[:error] = "You do not have download permissions."
      redirect_to(:action=>:index,
                  :object=>@version.inv_object,
                  :version=>@version) and return false
    end
  end

  before_filter(:only => [:download]) do
    check_dua(@version.inv_object.group.id, 
              @version,
              { :object  => @version.inv_object,
                :version => @version})
  end

  before_filter(:only => [:download]) do
    # if size is > 4GB, redirect to have user enter email for asynch
    # compression (skipping streaming)
    if exceeds_size(@version.inv_object) then
      redirect_to(:controller => "lostorage", 
                  :action => "index", 
                  :object => @version.inv_object, 
                  :version => @version) and return
    end
  end

  def load_version
    if (params[:version].to_i == 0) then
      latest_version = InvObject.find_by_ark(params_u(:object)).current_version.number
      redirect_to(:object => params[:object],
                  :version => latest_version)
    else
      @version = InvVersion.joins(:inv_object).
        where("inv_objects.ark = ?", params_u(:object)).
        where("inv_versions.number = ?", params_u(:version).to_i).
        first
      render :status => 404 and return if @version.nil?
    end
  end

  def index
  end

  def download
    stream_response("#{@version.bytestream_uri}?t=zip",
                    "attachment",
                    "#{Orchard::Pairtree.encode(@version.inv_object.ark.to_s)}_version_#{@version.number}.zip",
                    "application/zip")
    session[:perform_download] = false  
  end
end
