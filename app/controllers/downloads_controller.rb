class DownloadsController < ApplicationController
  def add()
    render(file: 'app/views/downloads/index.html.erb')
  end

  def get()
    if params.key?('available')
      redirect_to("https://merritt-stage.cdlib.org/d/ark%253A%252F99999%252Ffk4g46174f")
    else
      render(file: 'app/views/downloads/index.html.erb')
    end
  end
end
