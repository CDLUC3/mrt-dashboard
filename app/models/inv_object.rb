class InvObject < ActiveRecord::Base
  belongs_to :inv_owner

  has_many :inv_versions, inverse_of: :inv_object
  has_many :inv_files, through: :inv_versions

  has_many :inv_dublinkernels
  has_one  :inv_duas
  has_one  :inv_embargo

  has_many :inv_collections_inv_objects
  has_many :inv_collections, through: :inv_collections_inv_objects

  has_many :inv_nodes_inv_objects
  has_many :inv_nodes, through: :inv_nodes_inv_objects

  # hack to fix erc_ tables taking forever to load
  scope :quickloadhack, lambda {
    select(['inv_objects.id', 'inv_objects.version_number', 'inv_objects.inv_owner_id', 'inv_objects.object_type', 'inv_objects.role', 'inv_objects.aggregate_role', 'inv_objects.ark', 'inv_objects.created', 'inv_objects.modified', 'inv_objects.id', 'inv_objects.ark', 'inv_objects.created', 'inv_objects.modified'])
  }

  include Encoder

  def to_param
    urlencode(ark)
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

  # :nocov:
  def dua_exists?
    not inv_duas.blank?
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
    "#{APP_CONFIG['n2t_uri']}#{ark.to_s}"
  end
end
