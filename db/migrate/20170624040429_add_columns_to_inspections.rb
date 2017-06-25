class AddColumnsToInspections < ActiveRecord::Migration
  def change

    change_table :inspections do |t|
      # Existing:
      # t.integer  "visit_id"
      # t.integer  "report_id"
      # t.integer  "identification_type"
      # t.integer  "position",            default: 0
      # t.integer  "csv_id"
      # t.string   "source"
      # t.datetime "last_synced_at"
      # t.integer  "last_sync_seq"

      t.integer  :reporter_id
      t.integer  :eliminator_id
      t.integer  :location_id

      t.integer  :breeding_site_id
      t.integer  :elimination_method_id

      t.text     :description
      t.boolean  :protected
      t.boolean  :chemically_treated
      t.boolean  :larvae
      t.boolean  :pupae
      t.string   :field_identifier

      t.attachment :before_photo
      t.attachment :after_photo

      t.datetime :inspected_at
      t.datetime :eliminated_at

      t.string   :csv_uuid

      t.timestamps
    end
  end
end
