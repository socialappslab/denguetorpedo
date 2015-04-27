# -*- encoding : utf-8 -*-
class AddLarvaPupasColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :protected, :boolean
    add_column :reports, :chemically_treated, :boolean
    add_column :reports, :larvae, :boolean
    add_column :reports, :pupae, :boolean
  end
end
