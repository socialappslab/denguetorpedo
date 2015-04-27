# -*- encoding : utf-8 -*-
class AddPhotoToNotices < ActiveRecord::Migration
  def change
  	add_attachment :notices, :photo
  	add_column :notices, :summary, :text, :default => ""
  end
end
