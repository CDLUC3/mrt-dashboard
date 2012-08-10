class UpdateUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :displayname, :string
    add_column :users, :lastname, :string
    add_column :users, :firstname, :string
    add_column :users, :email, :string
    add_index  :users, :login, { :unique => true }
  end

  def self.down
    remove_column :users, :displayname
    remove_column :users, :lastname
    remove_column :users, :firstname
    remove_column :users, :email
    remove_index  :users, :login
  end
end
