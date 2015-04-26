# -*- encoding : utf-8 -*-
class AddObtainedOnToPrizeCode < ActiveRecord::Migration
  def change
    add_column :prize_codes, :obtained_on, :datetime
  end
end
