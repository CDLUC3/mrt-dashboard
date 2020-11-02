class InvEmbargo < ApplicationRecord
  self.table_name = 'inv_embargoes'
  belongs_to :inv_object

  def in_embargo?
    embargo_end_date >= Time.now.utc
  end
end
