class Post < ActiveRecord::Base
  attr_accessible :content, :title, :user_id, :parent_id
  acts_as_nested_set

  #----------------------------------------------------------------------------

  belongs_to :user
  has_one :feed, :as => :target
  belongs_to :wall, :polymorphic => true
  has_many :likes, :as => :likeable

  #----------------------------------------------------------------------------

  # validations
  # validates :title, presence: true
  validates :user_id, :presence => true
  validates :content, :presence => true, :length => {:minimum => 1}

  after_create :give_points
  after_destroy :remove_points
  after_create do |post|
    Feed.create_from_object(post, post.user_id, :post)
  end

  #----------------------------------------------------------------------------

  CHARACTER_LIMIT = 350

  #----------------------------------------------------------------------------

  def strf_created_at
    self.created_at.strftime("%d/%m/%Y")
  end

  def give_points
    self.user.update_attribute(:points, self.user.points + 5)
    self.user.update_attribute(:total_points, self.user.total_points + 5)
  end

  def remove_points
    self.user.update_attribute(:points, self.user.points - 5)
    self.user.update_attribute(:total_points, self.user.total_points - 5)
  end
end
