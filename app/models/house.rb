# -*- encoding : utf-8 -*-

# NOTE: THis is deprecated
class House < ActiveRecord::Base
  attr_accessible :name, :profile_photo, :address, :user, :user_id, :house_type, :location_id, :location_attributes, :neighborhood_id

  has_attached_file :profile_photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}, :default_url => 'default_images/house_default_image.png'#, :storage => STORAGE, :s3_credentials => S3_CREDENTIALS
  do_not_validate_attachment_file_type :profile_photo

  has_many :members, :class_name => "User"
  has_many :posts, :as => :wall
  has_many :reports, :through => :members
  has_one :user

  belongs_to :location
  belongs_to :neighborhood

  accepts_nested_attributes_for :location, :allow_destroy => true

  ## validations
  validates :name, :presence => true # :message => "Preencha o nome da casa"
  validates :name, :length => { :minimum => 2 } #, :message => "Insira um nome da casa válido"
  validates :neighborhood_id, :presence => true

  #----------------------------------------------------------------------------

  def points
    members.sum(:total_points)
  end

  #----------------------------------------------------------------------------

  def complete_address
    self.location.complete_address
  end

  def self.find_or_create(name, address, neighborhood, profile_photo=nil)
    if name.nil? || name.blank?
      return nil
    end

    # try to find the house, and return if it exists
    house = House.find_by_name(name)
    if house
      if profile_photo
        house.profile_photo = profile_photo
      end
      house.save
      return house
    end

    # create the location
    location = Location.find_or_create(address, neighborhood)

    if location.nil?
      return nil
    end

    house = House.find_by_location_id(location.id)

    if house
      if profile_photo
        house.profile_photo = profile_photo
      end
      house.save
      return house
    end

    # create the house
    house = House.new(name: name)
    house.location = location
    if profile_photo
      house.profile_photo = profile_photo
    end
    house.save

    # return the new house
    return house
  end
end
