# -*- encoding : utf-8 -*-
class AddVisitTypeDeprecateStatusInVisits < ActiveRecord::Migration
  def up
    add_column    :visits, :visit_type, :integer
    add_column    :visits, :visited_at, :datetime
    remove_column :visits, :status
  end

  def down
    add_column    :visits, :status, :integer
    remove_column :visits, :visit_type
    remove_column :visits, :visited_at, :datetime
  end
end
