class HomeController < ApplicationController
  before_filter :require_user,    :only => :choose_collection
  before_filter :group_optional

  def choose_collection
    @groups = current_user.groups.sort_by{|group| group.description.downcase }
    if @groups.length == 1 then
      redirect_to(:controller => 'collection', 
                  :action => 'index', 
                  :group => @groups[0].id)
      return false
    end
  end
end
