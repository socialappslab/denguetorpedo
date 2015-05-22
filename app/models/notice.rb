# -*- encoding : utf-8 -*-
class Notice < ActiveRecord::Base
  attr_accessible :date, :description, :location, :title, :summary, :photo, :institution_name, :neighborhood_id
  has_attached_file :photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}
  validates_attachment :photo, content_type: { content_type: /\Aimage\/.*\Z/ }

  #----------------------------------------------------------------------------

  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable
  belongs_to :user
  belongs_to :neighborhood

  #----------------------------------------------------------------------------

  validates :title, :presence => true
  validates :description, :presence => true

  #----------------------------------------------------------------------------

  scope :upcoming, -> { where("date > ?", Time.zone.now.beginning_of_day) }

  #----------------------------------------------------------------------------

  def display_name
    return self.institution_name.present? ? self.institution_name : I18n.t("activerecord.models.notice")
  end

  def picture(size = nil)
    if self.photo_file_name.nil?
      return "default_images/house_default_image.png"
    end

    return self.photo.url(size.present? ? size : :small)
  end
end
