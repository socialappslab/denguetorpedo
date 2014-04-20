# encoding: utf-8
class HousesController < NeighborhoodsBaseController
  before_filter :require_login

  def show
    @house = House.includes(:members, :posts, :location).find(params[:id])

    head :not_found and return if @house.nil?
    head :not_found and return if @house.user.role == "lojista"

    @post = Post.new
    excluded_roles = ["lojista", "verificador"]
    @mare = Neighborhood.find_by_name('Maré')
    @neighbors = House.joins(:location).joins(:user)
    @neighbors = @neighbors.where(:locations => { :neighborhood_id => @neighborhood.id})
    @neighbors = @neighbors.where('users.role NOT IN (?) AND houses.id != ?', excluded_roles, @house.id).uniq.shuffle[0..6]
    @highlightHouseItem = ""

    @marker = [{"lat" => @house.location.latitude, "lng" => @house.location.longitude}].to_json
    @markers = @house.reports.map { |report| report.location && report.location.info}
    @open_markers = @house.created_reports.map { |report| report.location && report.location.info}
    @eliminated_markers = @house.eliminated_reports.map { |report| report.location && report.location.info}

    # @counts = @house.reports.group(:location_id).count
    # @open_counts = @house.created_report.group(:location_id).count
    # @eliminated_reports = @house.eliminated_reports.group(:location_id).count

    @counts = @house.report_counts
    @open_counts = @house.open_report_counts
    @eliminated_counts = @house.eliminated_report_counts

    if (@current_user != nil && @current_user.house_id == @house.id)
      @highlightHouseItem = "nav_highlight"
    end

  end
end
