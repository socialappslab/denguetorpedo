# -*- encoding : utf-8 -*-
class CreateInspections < ActiveRecord::Migration
  def up
    create_table :inspections do |t|
      t.integer :visit_id
      t.integer :report_id
      t.integer :identification_type
    end
  end

  def down
    drop_table :inspections
  end
end
