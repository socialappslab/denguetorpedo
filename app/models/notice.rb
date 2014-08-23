class Notice < ActiveRecord::Base
  attr_accessible :date, :description, :location, :title, :summary, :photo, :institution_name, :neighborhood_id
  has_attached_file :photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}

  #----------------------------------------------------------------------------

  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable

  #----------------------------------------------------------------------------

  validates :title, :presence => true
  validates :description, :presence => true
end
