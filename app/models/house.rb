# encoding: UTF-8

# == Schema Information
#
# Table name: houses
#
#  id                         :integer          not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  name                       :string(255)
#  featured_event_id          :integer
#  location_id                :integer
#  profile_photo_file_name    :string(255)
#  profile_photo_content_type :string(255)
#  profile_photo_file_size    :integer
#  profile_photo_updated_at   :datetime
#  phone_number               :string(255)      default("")
#  house_type                 :string(255)      default("morador")
#  user_id                    :integer
#

class House < ActiveRecord::Base
  attr_accessible :name, :profile_photo, :address, :user, :user_id, :house_type, :location_id, :location_attributes, :neighborhood_id

  has_attached_file :profile_photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}, :default_url => 'default_images/house_default_image.png'#, :storage => STORAGE, :s3_credentials => S3_CREDENTIALS

  has_many :members, :class_name => "User"
  has_many :posts, :as => :wall
  has_many :all_reports, :through => :members
  has_many :created_reports, :through => :members, :conditions => {:status_cd => 0}
  has_many :eliminated_reports, :through => :members, :conditions => {:status_cd => 1}

  belongs_to :location
  belongs_to :neighborhood

  has_one :user
  accepts_nested_attributes_for :location, :allow_destroy => true

  ## validations

  validates_presence_of :name, :message => "Preencha o nome da casa"
  validates_length_of   :name, :minimum => 2, :message => "Insira um nome da casa válido"


  validates :neighborhood_id, :presence => true

  #----------------------------------------------------------------------------

  def points
    members.sum(:total_points)
  end

  #----------------------------------------------------------------------------

  def complete_address
    self.location.complete_address
  end

  #----------------------------------------------------------------------------

  def reports
    _reports = Report.find_by_sql(%Q(SELECT DISTINCT "reports".* FROM "reports", "users" WHERE (("reports".reporter_id = "users".id OR "reports".eliminator_Id = "users".id) AND "users".house_id = #{id}) ORDER BY "reports".updated_at DESC))
    ActiveRecord::Associations::Preloader.new(_reports, [:location]).run
    _reports
  end

  def report_counts
    self.reports.inject(Hash.new(0)) { |h, e| h[e.location_id] += 1; h }
  end

  def open_report_counts
    self.created_reports.inject(Hash.new(0)) { |h, e| h[e.location_id] += 1; h }
  end

  def eliminated_report_counts
    self.eliminated_reports.inject(Hash.new(0)) { |h, e| h[e.location_id] += 1; h }
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

    # address is not required
    #return nil if address.nil? || address.blank?

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
