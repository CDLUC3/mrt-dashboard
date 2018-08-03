class HomeController < ApplicationController
  before_filter :require_user, only: :choose_collection

  # :nocov:
  def index_new
    respond_to do |format|
      format.html { render layout: false }
    end
  end
  # :nocov:

  def choose_collection
    return unless available_groups.length == 1
    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end
end
