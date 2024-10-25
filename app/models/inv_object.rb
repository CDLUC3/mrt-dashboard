class InvObject < ApplicationRecord
  include MerrittRetryMixin

  belongs_to :inv_owner, inverse_of: :inv_objects

  has_many :inv_versions, inverse_of: :inv_object
  has_many :inv_files, through: :inv_versions

  has_many :inv_dublinkernels
  has_one :inv_embargo

  has_many :inv_collections_inv_objects
  has_many :inv_collections, through: :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, through: :inv_nodes_inv_objects

  has_many(:inv_localids, foreign_key: 'inv_object_ark', primary_key: 'ark')

  # work around erc_ tables taking forever to load
  scope :quickloadhack, -> {
    columns = %w[
      inv_objects.id
      inv_objects.version_number
      inv_objects.inv_owner_id
      inv_objects.object_type
      inv_objects.role
      inv_objects.aggregate_role
      inv_objects.ark
      inv_objects.created
      inv_objects.modified
      inv_objects.id
      inv_objects.ark
      inv_objects.created
      inv_objects.modified
    ]
    select(columns)
  }

  def to_param
    Encoder.urlencode(ark)
  end

  # content
  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{node_number}/#{to_param}")
  end

  # producer
  def bytestream_uri2
    URI.parse("#{APP_CONFIG['uri_2']}#{node_number}/#{to_param}")
  end

  # manifest
  def bytestream_uri3
    URI.parse("#{APP_CONFIG['uri_3']}#{node_number}/#{to_param}")
  end

  def node_number
    inv_nodes.where('inv_nodes_inv_objects.role' => 'primary').select('inv_nodes.number').map(&:number).first
  end

  def size
    inv_files.sum('billable_size')
  end

  def total_actual_size
    inv_files.sum('full_size')
  end

  def current_version
    merritt_retry_block do
      @current_version ||= inv_versions.order('number desc').first
    end
  end

  def inv_collection
    merritt_retry_block do
      @inv_collection ||= inv_collections.first
    end
  end

  def group
    return nil if inv_collection.nil?
    
    inv_collection.group
  end

  def permalink
    "#{APP_CONFIG['n2t_uri']}#{ark}"
  end

  def all_local_ids
    merritt_retry_block do
      inv_localids.map(&:local_id)
    end
  end

  def exceeds_download_size?
    total_actual_size > APP_CONFIG['max_download_size']
  end

  def exceeds_sync_size?
    total_actual_size > APP_CONFIG['max_archive_size']
  end

  def in_embargo?
    return false unless inv_embargo

    inv_embargo.in_embargo?
  end

  def user_has_read_permission?(uid)
    return false if group.nil?

    group.user_has_read_permission?(uid)
  end

  def user_can_download?(uid)
    return false if group.nil?

    permissions = group.user_permissions(uid)
    if permissions.member?('admin')
      true
    elsif in_embargo?
      false
    else
      permissions.member?('download')
    end
  end

  def object_info
    maxfile = 2500
    json = object_info_json
    object_info_add_localids(json)
    filecount = object_info_add_versions(json, maxfile)

    json['total_files'] = filecount
    json['included_files'] = [filecount, maxfile].min

    json
  end

  def object_info_json
    {
      ark: ark,
      version_number: version_number,
      created: created,
      modified: modified,
      erc_who: erc_who,
      erc_what: erc_what,
      erc_when: erc_when,
      versions: [],
      localids: [],
      prune_v1: [],
      prune_v2: [],
      prune_evaluated: false
    }
  end

  def object_info_add_localids(json)
    inv_localids.each do |loc|
      json[:localids].push(loc.local_id)
    end
  end

  def object_info_add_versions(json, maxfile)
    filecount = 0
    inv_versions.each do |ver|
      merritt_retry_block do
        v = {
          version_number: ver.number,
          created: ver.created,
          file_count: ver.inv_files.length,
          files: []
        }
        ver.inv_files.each do |f|
          filecount += 1
          v[:files].push(object_info_files(f)) unless filecount > maxfile
        end
        json[:versions].prepend(v)
      end
    end
    begin
      add_prune(json) if filecount < maxfile
      json[:prune_evaluated] = (filecount < maxfile)
    rescue StandardError
      # suppress any errors from the pruning algorithm
    end
    filecount
  end

  # :nocov:
  def add_prune(json)
    digests = {}
    paths = {}
    curv = json[:versions][0]
    vn = curv[:version_number]
    curv[:files].each do |f|
      paths[f[:pathname]] = vn
      digests[f[:digest_value]] = vn
    end
    json[:versions].each do |v|
      next if v[:version_number] == vn

      v[:files].each do |f|
        next unless f[:full_size] == f[:billable_size]

        p = f[:pathname]
        rec = { pathname: p, billable_size: f[:billable_size], version: v[:version_number] }
        next if paths.key?(p)

        json[:prune_v1].append(rec) unless json[:prune_v1].include?(p)
        next unless digests.key?(f[:digest_value])

        json[:prune_v2].append(rec) unless json[:prune_v2].include?(p)
      end
    end
  end
  # :nocov:

  def object_info_files(file)
    {
      pathname: file.pathname,
      full_size: file.full_size,
      billable_size: file.billable_size,
      mime_type: file.mime_type,
      digest_value: file.digest_value,
      digest_type: file.digest_type
    }
  end

  def new_version_sql(datestr)
    %{
      select
        'versions' as class,
        'New Versions' as title,
        (select count(*) from inv_versions where inv_object_id = #{id}
          and created > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_versions where inv_object_id = #{id}
          and created > date_add(now(), #{datestr})) as completed,
        null as started,
        null as err
    }
  end

  def new_file_sql(datestr)
    %{
      select
        'files' as class,
        'New Files' as title,
        (select count(*) from inv_files where inv_object_id = #{id}
          and created > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_files where inv_object_id = #{id}
          and created > date_add(now(), #{datestr})) as completed,
        null as started,
        null as err
    }
  end

  def audit_sql(datestr)
    %{
      select
        'audits' as class,
        'Audits' as title,
        (select count(*) from inv_audits where inv_object_id = #{id}
          and verified > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_audits where inv_object_id = #{id}
          and verified > date_add(now(), #{datestr}) and status='verified') as completed,
        (select count(*) from inv_audits where inv_object_id = #{id}
          and verified > date_add(now(), #{datestr}) and status='processing') as started,
        (select count(*) from inv_audits where inv_object_id = #{id}
          and verified > date_add(now(), #{datestr}) and status not in ('processing','verified')) as err
    }
  end

  def replic_sql(datestr)
    %{
      select
        'replics' as class,
        'Replications' as title,
        (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
          and replicated > date_add(now(), #{datestr})) as total,
        (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
          and replicated > date_add(now(), #{datestr}) and completion_status='ok') as completed,
        (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
          and replicated > date_add(now(), #{datestr}) and ifnull(completion_status, 'unknown') = 'unknown') +
          (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
            and replicated is null and replic_start > date_add(now(), #{datestr}) and ifnull(completion_status, 'unknown') = 'unknown') +
          (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
            and replicated is null and replic_start is null and created > date_add(now(), #{datestr})
            and ifnull(completion_status, 'unknown') = 'unknown') as started,
        (select count(*) from inv_nodes_inv_objects where inv_object_id = #{id}
          and replicated > date_add(now(), #{datestr}) and completion_status in ('fail','partial')) as err
    }
  end

  def audit_replic_stats(datestr)
    sql = %(
      #{new_version_sql(datestr)}
      union
      #{new_file_sql(datestr)}
      union
      #{audit_sql(datestr)}
      union
      #{replic_sql(datestr)}
      ;
    )
    ActiveRecord::Base.connection.execute(sql).to_a
  end
end
