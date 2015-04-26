# -*- encoding : utf-8 -*-
class AddVisitIdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :visit_id, :integer
  end
end
