class InvEmbargo < ActiveRecord::Base
  self.table_name = 'inv_embargoes'
  belongs_to :inv_object

  def in_embargo?
    self.embargo_end_date >= DateTime.now
  end
end
