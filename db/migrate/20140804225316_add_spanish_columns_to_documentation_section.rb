# -*- encoding : utf-8 -*-
class AddSpanishColumnsToDocumentationSection < ActiveRecord::Migration
  def change
    add_column :documentation_sections, :title_in_es, :string
    add_column :documentation_sections, :content_in_es, :text
  end
end
