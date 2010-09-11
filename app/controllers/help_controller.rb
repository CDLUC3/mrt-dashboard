class HelpController < ApplicationController
  before_filter :require_user
  before_filter :require_group
end
