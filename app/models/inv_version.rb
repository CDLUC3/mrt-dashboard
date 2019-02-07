class InvVersion < ActiveRecord::Base
  belongs_to :inv_object, inverse_of: :inv_versions
  has_many :inv_files, inverse_of: :inv_version
  has_many :inv_dublinkernels

  def to_param
    number
  end

  def permalink
    "#{APP_CONFIG['merritt_server']}/m/#{inv_object.to_param}/#{to_param}"
  end

  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{inv_object.node_number}/#{inv_object.to_param}/#{to_param}")
  end

  def bytestream_uri2
    URI.parse("#{APP_CONFIG['uri_2']}#{inv_object.node_number}/#{inv_object.to_param}/#{to_param}")
  end

  def total_size
    inv_files.sum('full_size')
  end

  def system_files
    inv_files.system_files.order(:pathname)
  end

  def producer_files
    inv_files.producer_files.order(:pathname)
  end

  def metadata(element)
    inv_dublinkernels.select { |md| md.element == element && md.value != '(:unas)' }.map(&:value)
  end

  def dk_who
    metadata('who')
  end

  def dk_what
    metadata('what')
  end

  def dk_when
    metadata('when')
  end

  def dk_where
    metadata('where')
  end

  def local_id
    # TODO: LOCALIDS use inv_local_ids
    dk_where.reject { |v| v == ark }
  end

  def total_actual_size
    inv_files.sum('full_size')
  end

  def exceeds_sync_size?
    total_actual_size > APP_CONFIG['max_archive_size']
  end

  def exceeds_download_size?
    total_actual_size > APP_CONFIG['max_download_size']
  end
end
