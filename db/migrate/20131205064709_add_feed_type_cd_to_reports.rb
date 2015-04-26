# -*- encoding : utf-8 -*-
class AddFeedTypeCdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :feed_type_cd, :integer
  end
end
