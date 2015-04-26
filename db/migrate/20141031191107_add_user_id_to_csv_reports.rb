# -*- encoding : utf-8 -*-
class AddUserIdToCsvReports < ActiveRecord::Migration
  def change
    add_column :csv_reports, :user_id, :integer
  end
end
