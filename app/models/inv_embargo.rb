class InvEmbargo < ActiveRecord::Base
  belongs_to :inv_object

  def in_embargo
    self.embargo_end_date < DateTime.now
  end
end
