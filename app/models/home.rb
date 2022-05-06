class Home < ApplicationRecord
  def self.new_object_sql(datestr)
    %{
      select
        'New Objects' as title,
        (select count(*) from inv_objects where created > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_objects where created > date_add(now(), #{datestr})) as completed,
        null as started,
        null as err
    }
  end

  def self.new_version_sql(datestr)
    %{
      select
        'Object Versions' as title,
        (select count(*) from inv_versions where created > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_versions where created > date_add(now(), #{datestr})) as completed,
        null as started,
        null as err
    }
  end

  def self.audit_sql(datestr)
    %{
      select
        'Audits' as title,
        (select count(*) from inv_audits where verified > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_audits where verified > date_add(now(), #{datestr})
          and status='verified') as completed,
        (select count(*) from inv_audits where verified > date_add(now(), #{datestr})
          and status='processing') as started,
        (select count(*) from inv_audits where verified > date_add(now(), #{datestr})
          and status not in ('processing','verified')) as err
    }
  end

  def self.replic_sql(datestr)
    %{
      select
        'Replications' as title,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{datestr})
          and completion_status='ok') as completed,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{datestr})
          and ifnull(completion_status, 'unknown') = 'unknown') +
          (select count(*) from inv_nodes_inv_objects where replicated is null and replic_start > date_add(now(), #{datestr})
            and ifnull(completion_status, 'unknown') = 'unknown') +
          (select count(*) from inv_nodes_inv_objects where replicated is null and replic_start is null and created > date_add(now(), #{datestr})
            and ifnull(completion_status, 'unknown') = 'unknown') as started,
        (select count(*) from inv_nodes_inv_objects where replicated > date_add(now(), #{datestr})
          and completion_status in ('fail','partial')) as err
    }
  end

  def self.audit_replic_stats
    @datestr = 'INTERVAL -15 MINUTE'
    sql = %(
      #{new_object_sql(@datestr)}
      union
      #{new_version_sql(@datestr)}
      union
      #{audit_sql(@datestr)}
      union
      #{replic_sql(@datestr)}
      ;
    )
    ActiveRecord::Base.connection.execute(sql).to_a
  end

end
