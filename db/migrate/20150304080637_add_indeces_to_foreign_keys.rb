# -*- encoding : utf-8 -*-
class AddIndecesToForeignKeys < ActiveRecord::Migration
  def change
    # Add index on the polymorphic associations.
    add_index :likes,    [:likeable_id, :likeable_type]
    add_index :comments, [:commentable_id, :commentable_type]

    # Add index on the authentication token.
    add_index :users, :auth_token

    # Add indices on common user-related objects.
    add_index :reports, :reporter_id
    add_index :reports, :eliminator_id
    add_index :user_notifications, :user_id

    # Add uniqueness constraint on user_id, team_id combination
    add_index :team_memberships, [:user_id, :team_id], :unique => true
  end
end
