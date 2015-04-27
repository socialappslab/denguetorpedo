# -*- encoding : utf-8 -*-
class AddCreditedAtToReports < ActiveRecord::Migration
  def change
    add_column :reports, :credited_at, :timestamp
  end
end
