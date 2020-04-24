class DownloadsController < ApplicationController
  def add
    render(action: 'index')
  end

  def get
    do_presign_obj_by_token(params[:token], params[:no_redirect])
  end
end
