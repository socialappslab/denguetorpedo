# -*- encoding : utf-8 -*-
class AddEliminationTypeAndEliminationMethodToReports < ActiveRecord::Migration
  def change
    add_column :reports, :elimination_type, :string
    add_column :reports, :elimination_method, :string
  end
end
