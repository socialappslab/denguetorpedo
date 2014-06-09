# encoding: UTF-8

class Like < ActiveRecord::Base
  #----------------------------------------------------------------------------

  attr_accessible :user_id, :likeable_id, :likeable_type

  #----------------------------------------------------------------------------

  module Types
    POST           = "Post"
    REPORT         = "Report"
    COMMUNITY_NEWS = "Notice"
  end

  #----------------------------------------------------------------------------

  belongs_to :likeable, :polymorphic => true

  #----------------------------------------------------------------------------
end
