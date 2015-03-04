class Post < ActiveRecord::Base
  attr_accessible :content, :title, :user_id, :parent_id, :neighborhood_id
  attr_readonly   :likes_count
  
  #----------------------------------------------------------------------------

  belongs_to :neighborhood
  belongs_to :user
  has_one :feed, :as => :target

  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable

  #----------------------------------------------------------------------------

  validates :user_id, :presence => true
  validates :content, :presence => true, :length => {:minimum => 1}

  #----------------------------------------------------------------------------

  CHARACTER_LIMIT = 350

  #----------------------------------------------------------------------------
end
