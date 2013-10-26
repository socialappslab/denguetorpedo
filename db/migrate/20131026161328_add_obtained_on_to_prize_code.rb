class AddObtainedOnToPrizeCode < ActiveRecord::Migration
  def change
    add_column :prize_codes, :obtained_on, :DateTime
  end
end
