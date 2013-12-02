class AddPrazoToPrizes < ActiveRecord::Migration
  def change
    add_column :prizes, :prazo, :boolean, default: true
  end
end
