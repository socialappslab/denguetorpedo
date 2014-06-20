class CreateTeams < ActiveRecord::Migration
  def up
    create_table :teams do |t|
      t.string  :name
      t.integer :neighborhood_id

      t.string   "profile_photo_file_name"
      t.string   "profile_photo_content_type"
      t.integer  "profile_photo_file_size"
      t.datetime "profile_photo_updated_at"

      t.timestamps
    end
  end

  def down
    drop_table :teams
  end
end
