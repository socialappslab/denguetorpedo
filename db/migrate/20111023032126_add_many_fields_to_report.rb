# -*- encoding : utf-8 -*-
class AddManyFieldsToReport < ActiveRecord::Migration
  def change
    add_column :reports, :eliminator_id, :integer
    rename_column :reports, :user_id, :reporter_id
  end
end
