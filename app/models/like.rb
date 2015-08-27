# -*- encoding : utf-8 -*-

class Like < ActiveRecord::Base
  attr_accessible :user_id, :likeable_id, :likeable_type

  #----------------------------------------------------------------------------

  belongs_to :likeable, :polymorphic => true, :counter_cache => true
  belongs_to :user

  #----------------------------------------------------------------------------
end
