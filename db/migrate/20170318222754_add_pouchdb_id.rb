class AddPouchdbId < ActiveRecord::Migration
  def change
    add_column :visits,      :pouchdb_id, :string
    add_column :locations,   :pouchdb_id, :string
  end
end
