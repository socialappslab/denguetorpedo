# -*- encoding : utf-8 -*-
class AddProfilePhotoToNeighborhoods < ActiveRecord::Migration
  def up
    add_attachment :neighborhoods, :photo
  end

  def down
    remove_attachment :neighborhoods, :photo
  end
end
