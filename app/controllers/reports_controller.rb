# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController
  before_filter :require_login,             :except => [:index, :gateway, :notifications]
  before_filter :find_by_id,                :only   => [:verify, :verify_report, :eliminate, :update, :like, :comment]
  before_filter :ensure_team_chosen,        :only   => [:index]
  before_filter :ensure_coordinator,        :only   => [:coordinator_edit, :coordinator_update]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/:neighborhood_id/reports

  def index
    @reports = Report.includes(:likes, :location).where(:neighborhood_id => @neighborhood.id)
    @reports = @reports.displayable.completed
    @reports = @reports.order("created_at DESC")

    # Now, let's filter by type of report chosen.
    if params[:reports].present?
      if params[:reports].strip.downcase == "open"
        @reports = @reports.is_open
      elsif params[:reports].strip.downcase == "eliminated"
        @reports = @reports.eliminated
      end
    end

    # At this point, we can start limiting the number of reports we return.
    @report_count  = @reports.count
    @report_limit  = 20
    @report_offset = (params[:page] || 0).to_i * @report_limit

    # Bypass method definitions for open/eliminated locations by directly
    # chaining AR queries here.
    reports_with_locs     = Report.joins(:location).select("latitude, longitude")
    @open_locations       = reports_with_locs.is_open
    @eliminated_locations = reports_with_locs.eliminated

    # NOTE: We don't want to do this *before* we define @open_ and @eliminated_
    # locations because we want the heatmap to include all the data.
    # Remove report that incurred an error, it should be at the top already
    @reports = @reports.limit(@report_limit).offset(@report_offset)

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited reports page", :properties => {:neighborhood => @neighborhood.name} ) if Rails.env.production?
    else
      Analytics.track(:anonymous_id => SecureRandom.base64, :event => "Visited reports page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    end
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/:neighborhood_id/reports/:id

  def show
    @report = @neighborhood.reports.find_by_id( params[:id] )
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/:id/reports/new

  def new
    @report          = Report.new
    @report.location = Location.new
  end

  #-----------------------------------------------------------------------------
  # POST /neighborhoods/1/reports

  def create
    # NOTE: Since we're no longer using the original uploaded image files,
    # we're excluding before_photo params (whatever it may be). Instead,
    # we're going to use before_photo_compressed attribute.
    params[:report].except!(:before_photo)

    @report                 = Report.new(params[:report])
    @report.reporter_id     = @current_user.id
    @report.neighborhood_id = @neighborhood.id

    # Set location, and validate on its attributes
    @location        = find_or_create_location_from_params(params[:location])
    @report.location = @location
    render "new" and return unless @location.update_attributes(params[:location])

    # Set the before photo
    if params[:has_before_photo].nil?
      flash[:alert] = I18n.t("views.reports.missing_has_before_photo")
      render "new" and return
    end

    @report.save_without_before_photo = (params[:has_before_photo].to_i == 0)

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank? && @report.save_without_before_photo == false
      flash[:alert] = I18n.t("activerecord.attributes.report.before_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      render "new" and return
    elsif base64_image.present?
      filename             = @current_user.display_name.underscore + "_report.jpg"
      paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
      @report.before_photo = paperclip_image
    end

    if @report.save
      # TODO: Deprecate completed_at
      @report.update_column(:completed_at, Time.zone.now)
      @report.update_column(:verified_at,  Time.zone.now)

      flash[:should_render_social_media_buttons] = true
      flash[:notice] = I18n.t("activerecord.success.report.create")

      # Finally, let's award the user for submitting a report.
      @current_user.award_points_for_submitting(@report)
      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      render "new" and return
    end

  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports/1/edit

  def edit
    @report = Report.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports/3/eliminate

  # This action is used exclusively for eliminating an existing report.
  def eliminate
    # Set the before photo
    if params[:has_after_photo].nil?
      flash[:alert] = "You need to specify if the report has an after photo or not!"
      render "edit" and return
    end

    @report.save_without_after_photo = (params[:has_after_photo].to_i == 0)

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank? && @report.save_without_after_photo == false
      flash[:alert] = I18n.t("activerecord.attributes.report.after_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      render "edit" and return
    elsif base64_image.present?
      filename  = @current_user.display_name.underscore + "_report.jpg"
      data      = prepare_base64_image_for_paperclip(base64_image, filename)
    end

    @report.after_photo   = data
    @report.eliminator_id = @current_user.id

    if @report.update_attributes(params[:report])
      Analytics.track( :user_id => @current_user.id, :event => "Eliminated a report", :properties => {:neighborhood => @neighborhood.name} ) if Rails.env.production?

      # Let's award the user for submitting a report.
      @current_user.award_points_for_eliminating(@report)
      flash[:notice] = I18n.t("activerecord.success.report.eliminate")
      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      render "edit" and return
    end
  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports/1/coordinator-edit

  def coordinator_edit
    @report = Report.find(params[:id])

    if @report.location.blank?
      @report.location = Location.new
      @report.location.latitude  ||= 0
      @report.location.longitude ||= 0
    end
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports/1/coordinator-update

  def coordinator_update
    @report = Report.find(params[:id])

    # Parse the created_at column.
    created_at = Time.zone.parse(params[:report][:created_at])
    created_at = Time.zone.now if created_at.blank?
    @report.created_at = created_at
    params[:report].delete(:created_at)

    # Parse the completed_at column.
    completed_at = Time.zone.parse(params[:report][:completed_at])
    completed_at = Time.zone.now if completed_at.blank?
    @report.completed_at = completed_at
    params[:report].delete(:completed_at)

    # Parse the eliminated_at column.
    eliminated_at = Time.zone.parse(params[:report][:eliminated_at])
    eliminated_at = Time.zone.now if eliminated_at.blank?
    @report.eliminated_at = eliminated_at
    params[:report].delete(:eliminated_at)

    base64_image = params[:report][:compressed_photo]
    params[:report].delete(:compressed_photo)
    if base64_image.present?
      filename  = @report.eliminator.display_name.underscore + "_report.jpg"
      data      = prepare_base64_image_for_paperclip(base64_image, filename)
      @report.after_photo = data
    end

    @report.assign_attributes(params[:report])
    @report.save(:validate => false)

    flash[:notice] = I18n.t("common_terms.saved")
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/1/reports/1/like

  def like
    count  = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 if (@report.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @report.likes.find {|like| like.user_id == @current_user.id }
    if existing_like.present?
      existing_like.destroy
      count -= 1
      liked  = false
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @report.id, :likeable_type => Report.name)
      count += 1
      liked  = true

      Analytics.track( :user_id => @current_user.id, :event => "Liked a report", :properties => {:report => @report.id}) if Rails.env.production?
    end

    render :json => {'count' => count.to_s, 'liked' => liked} and return
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/1/reports/1/comment

  def comment
    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    redirect_to :back and return if ( @current_user.blank? || @report.blank? )

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @report.id, :commentable_type => Report.name)
    c.content = params[:comment][:content]
    if c.save
      Analytics.track( :user_id => @current_user.id, :event => "Commented on a report", :properties => {:report => @report.id}) if Rails.env.production?
      redirect_to :back, :notice => I18n.t("activerecord.success.comment.create") and return
    else
      redirect_to :back, :alert => I18n.t("attributes.content") + " " + I18n.t("activerecord.errors.comments.blank") and return
    end
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/:neighborhood_id/reports/verify

  def verify
    @report.location ||= Location.new
  end

  #----------------------------------------------------------------------------
  # PUT /neighborhoods/:neighborhood_id/reports/:id/verify

  def verify_report
    # NOTE: Since we're no longer using the original uploaded image files,
    # we're excluding before_photo params (whatever it may be). Instead,
    # we're going to use before_photo_compressed attribute.
    params[:report].except!(:before_photo)

    if params[:has_before_photo].blank?
      flash[:alert] = I18n.t("views.reports.missing_has_before_photo")
      render "verify" and return
    end

    # Set the attr accessor on report to save with/without photo
    @report.save_without_before_photo = (params[:has_before_photo].to_i == 0)

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank? && @report.save_without_before_photo == false
      flash[:alert] = I18n.t("activerecord.attributes.report.before_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      render "verify" and return
    elsif base64_image.present?
      filename  = @current_user.display_name.underscore + "_report.jpg"
      data      = prepare_base64_image_for_paperclip(base64_image, filename)
    end

    # We set data on before_photo in this case since it come from an SMS,
    # which doesn't have an image.
    @report.before_photo = data

    # Verify report saves and form submission is valid
    if @report.update_attributes(params[:report])
      @report.update_column(:verified_at, Time.zone.now)

      # Let's award the user for submitting a report.
      @current_user.award_points_for_submitting(@report)

      redirect_to params[:redirect_path] || verify_csv_report_path(@report.csv_report) and return
    else
      render "verify" and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /reports/gateway
  # This is the path to which SMSBroadcastReceiver.java posts to when
  # the SMSGateway receives an SMS. It expects a JSON response which it
  # will display on the phone as a Toast (see
  # http://developer.android.com/reference/android/widget/Toast.html for more).
  # TODO: We will deprecate this once the Android device in Brazil stops sending requests.
  def gateway
    ender :nothing => true, :status => 400 and return
  end

  #----------------------------------------------------------------------------
  # GET /reports/notifications
  # This is used by SMSGateway to fetch the latest notifications created in
  # the 'gateway' action that will be sent out as SMS.
  # NOTE: Do not remove this unless you've removed the HTTP requests from the
  # Android app. I believe the frequent requests are causing memory issues for us.
  # For now, this action is a trivial action that returns an empty array.

  def notifications
    render :json => [] and return
  end

  #----------------------------------------------------------------------------

  private

  def find_by_id
    @report = Report.find(params[:id])
  end

  def ensure_coordinator
    redirect_to neighborhood_reports_path(@neighborhood) unless @current_user && @current_user.coordinator?
  end


  def find_or_create_location_from_params(location_params)
    location = Location.find_by_address(location_params[:address])
    if location.blank?
      location = Location.new
      location.save(:validate => false)
    end

    location.neighborhood = @neighborhood
    return location
  end
end
