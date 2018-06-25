class InvFile < ActiveRecord::Base
  belongs_to :inv_version, inverse_of: :inv_files
  belongs_to :inv_object
  scope :system_files, lambda { where("pathname LIKE 'system/%'") }
  scope :producer_files, lambda { where("pathname LIKE 'producer/%'") }
  scope :quickload_files, lambda { select(%w[mime_type pathname full_size inv_version_id]) }

  include Encoder

  def to_param
    urlencode(pathname)
  end

  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{inv_version.inv_object.node_number}/#{inv_version.inv_object.to_param}/#{inv_version.to_param}/#{to_param}")
  end
end
