class CreateDescriptions < ActiveRecord::Migration
  def change
    create_table :descriptions do |t|
      t.datetime :time
      t.string :text
      t.string :description
      t.string :updated_by

      t.timestamps
    end
  end
end
