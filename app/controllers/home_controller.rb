class HomeController < ApplicationController
  before_filter :require_user, only: :choose_collection

  def choose_collection
    if available_groups.length == 1
      redirect_to(controller: :collection,
                  action: :index,
                  group: available_groups[0][:id]) && return
    end
  end
end
