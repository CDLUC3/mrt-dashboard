class HomeController < ApplicationController
  before_action :require_user, only: :choose_collection

  def choose_collection
    return unless available_groups.length == 1

    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end
end
