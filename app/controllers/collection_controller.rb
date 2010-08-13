class CollectionController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  def index
    
  end
end
