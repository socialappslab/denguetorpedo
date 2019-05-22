class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.string :task
      t.references :city_block, index: true
      t.date :date
      t.string :status
      t.text :notes

      t.timestamps null: false
    end
    add_foreign_key :assignments, :city_blocks
  end
end
