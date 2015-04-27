# -*- encoding : utf-8 -*-
class CreateMessages < ActiveRecord::Migration
  def up
    create_table :messages do |t|
      t.text    :body
      t.integer :user_id
      t.integer :conversation_id

      t.timestamps
    end
  end

  def down
    drop_table :messages
  end
end
