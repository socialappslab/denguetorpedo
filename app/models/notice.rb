# == Schema Information
#
# Table name: notices
#
#  id                 :integer          not null, primary key
#  title              :string(255)      default("")
#  description        :text             default("")
#  location           :string(255)      default("")
#  date               :datetime
#  neighborhood_id    :integer
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#  summary            :text             default("")
#  institution_name   :string(255)
#

class Notice < ActiveRecord::Base
  attr_accessible :date, :description, :location, :title, :summary, :photo, :institution_name, :neighborhood_id, :hour

  has_attached_file :photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}

  def hour
  end
end
