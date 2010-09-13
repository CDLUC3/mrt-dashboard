class HelpController < ApplicationController
  before_filter :require_user
  before_filter :first_group_if_unset  #wackiness in which tracy included group information in help files breadcrumbs even though possibly not set from choose groups page
  before_filter :require_group_if_user
  #layout choose_layout

  #this chooses the first group if one isn't set since Tracy's help layout
  #requires a group, even though it might not have been chosen.  It's wacky
  #but a way to solve the shady layout she's using.
  def first_group_if_unset
    grps = current_user.groups
    redirect_to "/" and return false if grps.length < 1
    session[:group] = grps[0].id
    params[:group] = grps[0].id
  end

end
