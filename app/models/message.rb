# -*- encoding : utf-8 -*-

class Message < ActiveRecord::Base
  attr_accessible :body, :conversation_id, :user_id

  belongs_to :user
  belongs_to :conversation

  #----------------------------------------------------------------------------

  validates :body,            :presence => true
  validates :user_id,         :presence => true
  validates :conversation_id, :presence => true

  #----------------------------------------------------------------------------
end
