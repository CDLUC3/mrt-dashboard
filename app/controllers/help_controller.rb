class HelpController < ApplicationController
  before_filter :require_user
  before_filter :first_group_if_unset  #wackiness in which tracy included group information in help files breadcrumbs even though possibly not set from choose groups page
  before_filter :require_group_if_user
  #layout choose_layout

end
