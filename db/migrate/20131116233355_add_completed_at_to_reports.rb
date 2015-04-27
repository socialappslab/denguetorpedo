# -*- encoding : utf-8 -*-
class AddCompletedAtToReports < ActiveRecord::Migration
  def change
    add_column :reports, :completed_at, :timestamp
  end
end
