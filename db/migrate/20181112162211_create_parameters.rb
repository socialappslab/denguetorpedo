class CreateParameters < ActiveRecord::Migration
  def change
    create_table :parameters do |t|
      t.references :organization
      t.string :key
      t.text :value
    end
  end
end
