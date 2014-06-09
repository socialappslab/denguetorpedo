# encoding: UTF-8

class Like < ActiveRecord::Base
  #----------------------------------------------------------------------------

  attr_accessible :user_id, :likeable_id, :likeable_type

  #----------------------------------------------------------------------------

  module Types
    POST   = Post.name
    REPORT = Report.name
    NOTICE = Notice.name
  end

  #----------------------------------------------------------------------------

  belongs_to :likeable, :polymorphic => true

  #----------------------------------------------------------------------------
end
