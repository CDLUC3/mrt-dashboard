class AddTimezone < ActiveRecord::Migration
  def self.up
    add_column :users, :tz_region, :string
  end

  def self.down
    remove_column :users, :tz_region
  end
end
