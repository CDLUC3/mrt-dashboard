class ObjectController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  def add
    
  end

  def upload
    new_file = DataFile.save(params[:file], current_user.login)

    HTTPClient.post('')
    render :text => new_file + params.inspect.to_s

  end
end
