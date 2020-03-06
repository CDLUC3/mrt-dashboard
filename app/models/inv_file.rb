class InvFile < ActiveRecord::Base
  belongs_to :inv_version, inverse_of: :inv_files
  belongs_to :inv_object
  scope :system_files, -> { where("pathname LIKE 'system/%'") }
  scope :producer_files, -> { where("pathname LIKE 'producer/%'") }
  scope :quickload_files, -> { select(%w[mime_type pathname full_size inv_version_id]) }

  include Encoder

  def to_param
    urlencode(pathname)
  end

  def bytestream_uri
    URI.parse(
      File.join(
        APP_CONFIG['uri_1'],
        inv_version.inv_object.node_number.to_s,
        inv_version.inv_object.to_param,
        inv_version.to_param.to_s,
        to_param
      )
    )
  end

  # Construct outward facing download URL
  def external_bytestream_uri
    URI.parse(
      File.join(
        APP_CONFIG['merritt_server'],
        'd',
        inv_version.inv_object.to_param,
        inv_version.to_param.to_s,
        to_param
      )
    )
  end

  def exceeds_download_size?
    full_size > APP_CONFIG['max_download_size']
  end
end
