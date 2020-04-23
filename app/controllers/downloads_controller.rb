class DownloadsController < ApplicationController
  def add
    render(file: 'app/views/downloads/index.html.erb')
  end


  def index
    respond_to do |format|
      format.html
      format.json
    end
  end

  def get
    respond_to do |format|
      format.html
      format.json
    end
    do_presign_obj_by_token(params[:token], params[:no_redirect])
  end
end
