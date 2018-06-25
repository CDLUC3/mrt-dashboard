class InvEmbargo < ActiveRecord::Base
  self.table_name = 'inv_embargoes'
  belongs_to :inv_object

  def in_embargo?
    embargo_end_date >= DateTime.now.utc
  end
end
