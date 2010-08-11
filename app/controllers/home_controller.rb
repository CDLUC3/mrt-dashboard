class HomeController < ApplicationController

  layout 'home', :except => ['choose_collection']
  before_filter :require_user,    :only => :choose_collection

  def index
    
  end

  def choose_collection
    #return if require_user == false
    @grps = current_user.groups

    render :layout => 'no_collection'
  end
  
end
