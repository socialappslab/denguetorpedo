# -*- encoding : utf-8 -*-
class Post < ActiveRecord::Base
  attr_accessible :content, :title, :user_id, :parent_id, :neighborhood_id

  #----------------------------------------------------------------------------

  belongs_to :neighborhood
  belongs_to :user

  has_many :likes,    :as => :likeable,    :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy

  after_commit :add_hashtags,    :on => :create
  after_commit :update_hashtags, :on => :destroy

  #----------------------------------------------------------------------------

  has_attached_file :photo, :styles => {
    :large => ["517x400>", :jpg]
  }, :convert_options => { :large => "-quality 75 -strip" }

  #----------------------------------------------------------------------------

  validates :user_id, :presence => true
  validates :content, :presence => true, :length => {:minimum => 1}, :unless => Proc.new {|file| self.photo_file_size.present? }
  validates_attachment :photo, content_type: { content_type: /\Aimage\/.*\Z/ }

  #----------------------------------------------------------------------------

  CHARACTER_LIMIT = 350

  #----------------------------------------------------------------------------

  private

  # Iterate over the post's content, updating the Redis set of the corresponding
  # hashtags. This will run only once, on create.
  def add_hashtags
    return unless self.content.present?

    self.content.scan(/#\w*/).each do |hashtag|
      Hashtag.add_post_to_hashtag(self, hashtag)
    end
  end

  # Iterate over the post's content, updating the Redis set of the corresponding
  # hashtags. This will run only once, on create.
  def update_hashtags
    return unless self.content.present?

    self.content.scan(/#\w*/).each do |hashtag|
      Hashtag.remove_post_from_hashtag(self, hashtag)
    end
  end

  #----------------------------------------------------------------------------
end
