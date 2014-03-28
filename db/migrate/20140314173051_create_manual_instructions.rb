class CreateManualInstructions < ActiveRecord::Migration
  def change
    create_table :manual_instructions do |t|
      t.string :title
      t.text :description
      t.integer :user_id
      t.time :created_at
      t.time :updated_at

      t.timestamps
    end
  end
end
