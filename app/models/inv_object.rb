class InvObject < ActiveRecord::Base
  belongs_to :inv_owner

  has_many :inv_versions, inverse_of: :inv_object
  has_many :inv_files, through: :inv_versions

  has_many :inv_dublinkernels
  has_one :inv_duas
  has_one :inv_embargo

  has_many :inv_collections_inv_objects
  has_many :inv_collections, through: :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, through: :inv_nodes_inv_objects

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

  include Encoder

  def to_param
    urlencode(ark)
  end

  # content
  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{node_number}/#{to_param}")
  end

  def bytestream_uri_async
    bytestream_uri.to_s.gsub(/content/, 'async')
  end

  # producer
  def bytestream_uri2
    URI.parse("#{APP_CONFIG['uri_2']}#{node_number}/#{to_param}")
  end

  def bytestream_uri2_async
    bytestream_uri2.to_s.gsub(/producer/, 'producerasync')
  end

  # manifest
  def bytestream_uri3
    URI.parse("#{APP_CONFIG['uri_3']}#{node_number}/#{to_param}")
  end

  # :nocov:
  def dua_exists?
    !inv_duas.blank?
  end

  # :nocov:

  # :nocov:
  def dua_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{node_number}/#{inv_collection.to_param}/0/#{urlencode(APP_CONFIG['mrt_dua_file'])}")
  end

  # :nocov:

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
    @current_version ||= inv_versions.order('number desc').first
  end

  def inv_collection
    @inv_collection ||= inv_collections.first
  end

  def group
    inv_collection.group
  end

  def permalink
    "#{APP_CONFIG['n2t_uri']}#{ark}"
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
    group.user_has_permission?(uid, 'read')
  end

  def user_can_download?(uid)
    permissions = group.user_permissions(uid)
    if permissions.member?('admin')
      true
    elsif in_embargo?
      false
    else
      permissions.member?('download')
    end
  end
end
