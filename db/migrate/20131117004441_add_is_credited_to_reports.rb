# -*- encoding : utf-8 -*-
class AddIsCreditedToReports < ActiveRecord::Migration
  def change
    add_column :reports, :is_credited, :boolean
  end
end
