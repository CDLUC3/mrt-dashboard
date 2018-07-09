module ArkHelper
  def self.next_ark(type = 'anything')
    @next_ark_id = 1 + (@next_ark_id || 0)
    format("ark:/99999/fk_#{type}_%05d", @next_ark_id)
  end
end
