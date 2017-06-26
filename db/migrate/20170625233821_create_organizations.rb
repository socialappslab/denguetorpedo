class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.timestamps
    end

    create_table :memberships do |t|
      t.integer :organization_id
      t.integer :user_id
      t.string  :role,    :default => "morador"
      t.boolean :blocked, :default => false
      t.boolean :active,  :default => false

      t.timestamps
    end

    add_index :memberships, :organization_id
    add_index :memberships, :user_id
    add_index :memberships, [:organization_id, :user_id], :unique => true
  end
end
