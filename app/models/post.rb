class Post < ActiveRecord::Base
  attr_accessible :content, :title, :user_id, :parent_id, :neighborhood_id
  # attr_readonly   :likes_count

  #----------------------------------------------------------------------------

  belongs_to :neighborhood
  belongs_to :user
  has_one :feed, :as => :target

  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable

  #----------------------------------------------------------------------------

  has_attached_file :photo, :styles => {
    :large => ["517x400>", :jpg]
  }, :convert_options => { :large => "-quality 75 -strip" }

  #----------------------------------------------------------------------------

  validates :user_id, :presence => true
  validates :content, :presence => true, :length => {:minimum => 1}
  validates_attachment :photo, content_type: { content_type: /\Aimage\/.*\Z/ }

  #----------------------------------------------------------------------------

  CHARACTER_LIMIT = 350

  #----------------------------------------------------------------------------
end
