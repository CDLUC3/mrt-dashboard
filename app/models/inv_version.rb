class InvVersion < ApplicationRecord
  RETRY_LIMIT = 3

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
    retries = 0
    begin
      inv_files.sum('full_size')
    rescue StandardError => e
      retries += 1
      raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
  end

  def system_files
    retries = 0
    begin
      inv_files.system_files.order(:pathname)
    rescue StandardError => e
      retries += 1
      raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
  end

  def producer_files
    retries = 0
    begin
      inv_files.producer_files.order(:pathname)
    rescue StandardError => e
      retries += 1
      raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
  end

  def metadata(element)
    retries = 0
    begin
      inv_dublinkernels.select { |md| md.element == element && md.value != '(:unas)' }.map(&:value)
    rescue StandardError => e
      retries += 1
      raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
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
    dk_where.reject { |v| v == ark }
  end

  def total_actual_size
    retries = 0
    begin
      inv_files.sum('full_size')
    rescue StandardError => e
      retries += 1
      raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
  end

  def exceeds_sync_size?
    total_actual_size > APP_CONFIG['max_archive_size']
  end

  def exceeds_download_size?
    total_actual_size > APP_CONFIG['max_download_size']
  end
end
