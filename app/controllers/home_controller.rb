class HomeController < ApplicationController
  before_filter :require_user, only: :choose_collection

  def index
    respond_to do |format|
      # TODO: remove this once we've converted the new index page into a global layout
      format.html { render layout: false }
    end
  end

  def choose_collection
    return unless available_groups.length == 1
    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end
end
