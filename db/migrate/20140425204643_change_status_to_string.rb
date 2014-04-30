class ChangeStatusToString < ActiveRecord::Migration
  def change
    # NOTE: We get the following error in
    # staging:
    # PG::UndefinedColumn: ERROR:  column "status" of relation "reports" does not exist
    # remove_column :reports, :status
    add_column :reports, :status, :string
  end
end
