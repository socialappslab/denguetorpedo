# encoding: UTF-8

class Conversation < ActiveRecord::Base
  attr_accessible :name

  #----------------------------------------------------------------------------

  has_and_belongs_to_many :user
  has_many           :messages

  #----------------------------------------------------------------------------
end
