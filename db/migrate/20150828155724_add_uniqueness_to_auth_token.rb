class AddUniquenessToAuthToken < ActiveRecord::Migration
  def change
    remove_index :users, :auth_token
    add_index    :users, :auth_token, :unique => true
  end
end
