# -*- encoding : utf-8 -*-
class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen, :only => [:show]
  before_filter :calculate_ivars,    :only => [:show]
  before_filter :update_breadcrumb,  :except => [:invitation, :contact]
  before_action :calculate_header_variables

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @post = Post.new

    # Calculate total metrics before we start filtering.
    @total_reports = @reports.count

    # Limit the activity feed to *current* neighborhood members.
    user_ids = @users.pluck(:id)
    @reports = @reports.displayable.completed
    @reports = @reports.where("reporter_id IN (?) OR verifier_id IN (?) OR resolved_verifier_id IN (?) OR eliminator_id IN (?)", user_ids, user_ids, user_ids, user_ids)
    @reports = @reports.order("created_at DESC")

    # Limit the amount of records we show.
    unless params[:feed].to_s == "1"
      @reports = @reports.limit(10)
    end

    @activity_feed = @notices

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited a neighborhood page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited a neighborhood page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    end

    # Identify locations associated with this neighborhood.
    all_csv_loc_ids = Spreadsheet.pluck(:location_id)
    location_ids    = @neighborhood.locations.find_all {|loc| all_csv_loc_ids.include?(loc.id)}.map {|loc| loc.id}.uniq

    # Calculate the green houses.
    @green_location_count = GreenLocationSeries.get_latest_count_for_neighborhood(@neighborhood).to_i
    @locations_count      = location_ids.count
    @green_houses_percent = @locations_count == 0 ? "0%" : "#{(@green_location_count.to_f * 100 / @locations_count).round(0)}%"

    # Calculates positive eliminated % and potential eliminated %.
    # ins_ids     = Visit.where("visits.csv_id IS NOT NULL").where(:location_id => location_ids).includes(:inspections).pluck("inspections.id").compact.uniq
    # Report.includes(:inspections)
    @totals = {:positive => {:eliminated => Set.new, :total => Set.new}, :potential => {:eliminated => Set.new, :total => Set.new}}
    report_ids  = @neighborhood.reports.where(:location_id => location_ids).pluck(:id)
    inspections = Inspection.where("csv_id IS NOT NULL").where(:report_id => report_ids).order("position DESC").to_a
    report_ids.each do |r_id|
      types = inspections.find_all {|ins| ins.report_id == r_id}.map {|ins| ins.identification_type}
      if types.include?(Inspection::Types::POSITIVE)
        @totals[:positive][:total].add(r_id)
        @totals[:positive][:eliminated].add(r_id) if types.first == Inspection::Types::NEGATIVE
      end

      if types.include?(Inspection::Types::POTENTIAL)
        @totals[:potential][:total].add(r_id)
        @totals[:potential][:eliminated].add(r_id) if types.first == Inspection::Types::NEGATIVE
      end
    end

    [:positive, :potential].each do |key|
      @totals[key][:ratio] = @totals[key][:total].length == 0 ? 0 : (@totals[key][:eliminated].length.to_f / @totals[key][:total].length)
    end

    # James requested to display only Managua neighborhoods.
    @neighborhoods = Neighborhood.where(:city_id => 4).order("name ASC")
    @breadcrumbs << {:name => @neighborhood.name, :path => neighborhood_path(@neighborhood)}
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/invitation
  #------------------------------

  def invitation
    @feedback = Feedback.new
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/contact
  #------------------------------

  def contact
    @feedback = Feedback.new(params[:feedback])
    if @feedback.save
      UserMailer.delay.send_contact(@feedback)
      redirect_to invitation_neighborhoods_path, :notice => I18n.t("views.application.success") and return
    else
      render :invitation and return
    end

  end

  #----------------------------------------------------------------------------

  private

  def update_breadcrumb
    @breadcrumbs << {:name => @neighborhood.city.name, :path => city_path(@neighborhood.city)}
  end

  def calculate_ivars
    @neighborhood = Neighborhood.find(params[:id])
    @users   = @neighborhood.users.where(:is_blocked => false).order("first_name ASC")
    @teams   = @neighborhood.teams.order("name ASC")
    @reports = @neighborhood.reports
    @notices = @neighborhood.notices.order("updated_at DESC").upcoming
  end

end
