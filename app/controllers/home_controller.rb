class HomeController < ApplicationController
  before_action :require_user, only: :choose_collection

  def choose_collection
    return unless available_groups.length == 1

    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end

  def state
    @datestr = 'INTERVAL -15 MINUTE'
  end

  def state_audit_replic
    @datestr = 'INTERVAL -15 MINUTE'
    @count_by_status = Home.audit_replic_stats(@datestr)
  end
end
