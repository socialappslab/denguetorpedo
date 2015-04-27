# -*- encoding : utf-8 -*-
class CreateLocationStatuses < ActiveRecord::Migration
  def up
    create_table :location_statuses do |t|
      t.integer :location_id
      t.integer :status
      t.timestamps
    end
  end

  def down
    drop_table :location_statuses
  end
end
