# -*- encoding : utf-8 -*-

class Comment < ActiveRecord::Base
  attr_accessible :user_id, :commentable_id, :commentable_type

  #----------------------------------------------------------------------------

  belongs_to :commentable, :polymorphic => true
  belongs_to :user

  #----------------------------------------------------------------------------

  validates :content, :presence => true

  def formatted_created_at
    return "" if self.created_at.blank?
    return self.created_at.strftime("%Y-%m-%d %H:%M")
  end

end
