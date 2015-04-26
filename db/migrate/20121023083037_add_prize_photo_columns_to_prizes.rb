# -*- encoding : utf-8 -*-
class AddPrizePhotoColumnsToPrizes < ActiveRecord::Migration
  def self.up
    add_attachment :prizes, :prize_photo
  end

  def self.down
    remove_attachment :prizes, :prize_photo
  end
end
