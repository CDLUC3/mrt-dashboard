class HomeController < ApplicationController

  layout 'home', :except => ['choose_collection']
  before_filter :require_user,    :only => :choose_collection
  before_filter :require_group_if_user, :except => :choose_collection

  def choose_collection
    @groups = current_user.groups.sort{|x, y| x.description.downcase <=> y.description.downcase}
    if @groups.length == 1 then
      redirect_to :controller => 'collection', :action => 'index', :group => @groups[0].id
      return false
    end
    render :layout => 'no_collection'
  end
  
end
