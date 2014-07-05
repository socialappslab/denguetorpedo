# == Schema Information
#
# Table name: neighborhoods
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  coordinator_id :integer
#

class Neighborhood < ActiveRecord::Base
  attr_accessible :name

  has_many :locations

  # TODO: Deprecate houses association
  has_many :houses
  has_many :teams

  has_many :members, :class_name => "User"
  has_many :reports

  has_many :notices
  belongs_to :coordinator, :class_name => "User"
  has_many :health_agents, :through => :houses, :source => "members", :conditions => "is_health_agent = 1"

  validates :name, :presence => true


  #----------------------------------------------------------------------------
  # Geographical data
  #------------------

  # NOTE: this method returns a Country object.
  def country
    return Country[self.country_string_id]
  end

  def state
    c = self.country
    return c.states[self.state_string_id]["name"]
  end

  #----------------------------------------------------------------------------

  # TODO: Deprecate this.
  def total_reports
    # total_reports = []
    # self.members.each do |member|
    #   member.reports.each do |report|
    #     total_report = total_reports.append(report)
    #   end
    # end
    # total_reports

    return self.reports.to_a
  end

  def open_reports
    # open_reports = []
    # self.members.each do |member|
    #   member.reports.each do |report|
    #     open_report = open_reports.append(report) if report.status == Report::STATUS[:reported]
    #   end
    # end
    # open_reports

    return self.reports.where(:status => Report::STATUS[:reported]).to_a
  end

  def eliminated_reports
    # eliminated_reports = []
    # self.members.each do |member|
    #   member.reports.each do |report|
    #     eliminated_report = eliminated_reports.append(report) if report.status == Report::STATUS[:eliminated]
    #   end
    # end
    # eliminated_reports

    return self.reports.where(:status => Report::STATUS[:eliminated]).to_a
  end

  #----------------------------------------------------------------------------

  def total_points
    self.members.sum(:total_points)
  end

  #----------------------------------------------------------------------------

end
