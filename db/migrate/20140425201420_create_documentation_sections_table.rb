# -*- encoding : utf-8 -*-
class CreateDocumentationSectionsTable < ActiveRecord::Migration
  def up
    create_table :documentation_sections do |t|
      t.string :title
      t.text   :content
      t.integer :editor_id
      t.integer :creator_id

      t.timestamps
    end
  end

  def down
    drop_table :documentation_sections
  end
end
