module ArkHelper
  def self.next_ark(type)
    @next_ark_id = 1 + (@next_ark_id || 0)
    "ark:/99999/fk_#{type}_%05d" % @next_ark_id
  end
end
