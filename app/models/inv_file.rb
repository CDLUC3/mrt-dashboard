class InvFile < ActiveRecord::Base
  belongs_to :inv_version, :inverse_of => :inv_files
  belongs_to :inv_object
  scope :system_files, lambda { where("pathname LIKE 'system/%'") }
  scope :producer_files, lambda { where("pathname LIKE 'producer/%'") }

  include Encoder

  def to_param
    urlencode(self.pathname)
  end

  def bytestream_uri
    URI.parse("#{APP_CONFIG['uri_1']}#{self.inv_version.inv_object.node_number}/#{self.inv_version.inv_object.to_param}/#{self.inv_version.to_param}/#{self.to_param}")
  end
end
