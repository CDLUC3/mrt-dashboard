class DownloadsController < ApplicationController
  def add
    puts("add #{params[:token]}")
    render(file: 'app/views/downloads/index.html.erb')
  end

  def get
    presign_obj_by_token
  end
end
