# encoding: utf-8
class HousesController < NeighborhoodsBaseController
  before_filter :require_login

  def show
    @house = House.includes(:members, :posts, :location).find(params[:id])

    head :not_found and return if @house.nil?
    head :not_found and return if @house.user.role == "lojista"

    @post = Post.new
    excluded_roles = ["lojista", "verificador"]
    @mare      = Neighborhood.find_by_name('Maré')
    @neighbors = House.joins(:location).joins(:user)
    @neighbors = @neighbors.where(:locations => { :neighborhood_id => @neighborhood.id})
    @neighbors = @neighbors.where('users.role NOT IN (?) AND houses.id != ?', excluded_roles, @house.id).uniq.shuffle[0..6]

    # TODO: Make this specific to each neighborhood.
    @reports                  = @house.reports.find_all { |r| r.neighborhood_id == @neighborhood.id }
    @open_house_reports       = @reports.find_all { |r| r.status == Report::STATUS[:reported] }
    @eliminated_house_reports = @reports.find_all { |r| r.status == Report::STATUS[:eliminated] }

    @open_markers       = @open_house_reports.map { |report| report.location && report.location.as_json(:only => [:latitude, :longitude])}
    @eliminated_markers = @eliminated_house_reports.map { |report| report.location && report.location.as_json(:only => [:latitude, :longitude])}

    @open_markers.compact!
    @eliminated_markers.compact!
  end
end
