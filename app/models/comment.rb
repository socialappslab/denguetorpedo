# encoding: UTF-8

class Comment < ActiveRecord::Base
  attr_accessible :user_id, :commentable_id, :commentable_type

  #----------------------------------------------------------------------------

  belongs_to :commentable, :polymorphic => true

  #----------------------------------------------------------------------------
end
