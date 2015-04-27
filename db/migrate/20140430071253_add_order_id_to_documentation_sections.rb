# -*- encoding : utf-8 -*-
class AddOrderIdToDocumentationSections < ActiveRecord::Migration
  def change
    add_column :documentation_sections, :order_id, :integer
  end
end
