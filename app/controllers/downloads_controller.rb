class DownloadsController < ApplicationController
  def add
    puts("add #{params[:token]}")
    render(file: 'app/views/downloads/index.html.erb')
  end

  def get
    redirect_to(controller: :application, action: :presign_obj_by_token, token: params[:token])
  end
end
