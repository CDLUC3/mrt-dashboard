class HomeController < ApplicationController
  before_filter :require_user, only: :choose_collection

  def choose_collection
    return unless available_groups.length == 1
    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end

  private

  # Return the groups which the user may be a member of
  def available_groups
    groups = current_user.groups.sort_by { |g| g.description.downcase } || []
    groups.map do |group|
      { id:               group.id,
        description:      group.description,
        user_permissions: group.user_permissions(current_user.login) }
    end
  end
end
