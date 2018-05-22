module ArkHelper
  def self.next_ark
    @next_ark_id = 1 + (@next_ark_id || 0)
    "ark:/99999/fk_coll_%05d" % @next_ark_id
  end
end
