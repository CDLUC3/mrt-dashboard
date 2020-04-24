class DownloadsController < ApplicationController
  def add
    @tasks = Task.all
    respond_to :html, :json
    render(file: 'app/views/downloads/index.html.erb')
  end


  def index
    @tasks = Task.all
    respond_to :html, :json
  end

  def get
    do_presign_obj_by_token(params[:token], params[:no_redirect])
  end
end
