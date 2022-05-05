class HomeController < ApplicationController
  before_action :require_user, only: :choose_collection

  def choose_collection
    return unless available_groups.length == 1

    redirect_to(controller: :collection,
                action: :index,
                group: available_groups[0][:id])
  end

  def state
    @datestr = 'INTERVAL -15 MINUTE';
    sql = %{
      select
        'New Objects' as title,
        (select count(*) from inv_objects where created > date_add(now(), #{@datestr})) as total,
        (select count(*) from inv_objects where created > date_add(now(), #{@datestr})) as completed,
        null as started,
        null as err
      union
      select
        'Object Versions' as title,
        (select count(*) from inv_versions where created > date_add(now(), #{@datestr})) as total,
        (select count(*) from inv_versions where created > date_add(now(), #{@datestr})) as completed,
        null as started,
        null as err
      union
      select
        'Audits' as title,
        (select count(*) from inv_audits where verified > date_add(now(), #{@datestr})) as total,
        (select count(*) from inv_audits where verified > date_add(now(), #{@datestr}) and status='verified') as completed,
        (select count(*) from inv_audits where verified > date_add(now(), #{@datestr}) and status='processing') as started,
        (select count(*) from inv_audits where verified > date_add(now(), #{@datestr}) and status not in ('processing','verified')) as err
      union
      select
        'Replications' as title,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{@datestr})) as total,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{@datestr}) and completion_status='ok') as completed,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{@datestr}) and completion_status='unknown') as started,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{@datestr}) and completion_status not in ('ok','unknown')) as err
      ;
    }
    @count_by_status = ActiveRecord::Base.connection.execute(sql).to_a
  end
end
