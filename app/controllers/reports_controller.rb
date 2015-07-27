# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController
  before_filter :require_login,             :except => [:index, :verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id,                :only   => [:prepare, :eliminate, :update, :creditar, :credit, :discredit, :like, :comment]
  before_filter :ensure_team_chosen,        :only   => [:index]
  before_filter :ensure_coordinator,        :only => [:coordinator_edit, :coordinator_update]

  #----------------------------------------------------------------------------

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
    @report = Report.new
  end

  #-----------------------------------------------------------------------------
  # POST /neighborhoods/1/reports

  def create
    # Add the neighborhood id to location attributes before saving the report.
    # There are three different types of locations we may get:
    # 1. Full street type, name and number coming from Brazilian communities (to be deprecated),
    # 2. Single address field coming from Mexican communities,
    # 3. Vague neighborhood/district from Nicaraguan communities.
    # NOTE: We should NOT make any assumptions about pre-existing location
    # instances with same user input. For instance, if we already have a location
    # record with same :neighborhood string, then we should use the existing
    # location record. We should always choose the conservative option.
    params[:report][:location_attributes][:neighborhood_id] = @neighborhood.id

    # NOTE: Since we're no longer using the original uploaded image files,
    # we're excluding before_photo params (whatever it may be). Instead,
    # we're going to use before_photo_compressed attribute.
    params[:report].except!(:before_photo)


    @report = Report.new(params[:report])
    @report.reporter_id  = @current_user.id
    @report.neighborhood_id = @neighborhood.id

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank?
      flash[:alert] = I18n.t("activerecord.attributes.report.before_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      render "new" and return
    else
      filename             = @current_user.display_name.underscore + "_report.jpg"
      paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
      @report.before_photo = paperclip_image
    end

    if @report.save
      @report.update_column(:completed_at, Time.zone.now)

      flash[:should_render_social_media_buttons] = true
      flash[:notice] = I18n.t("activerecord.success.report.create")

      Analytics.track( :user_id => @current_user.id, :event => "Created a report", :properties => {:neighborhood => @neighborhood.name} ) if Rails.env.production?

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

    if @report.location.blank?
      @report.location = Location.new
      @report.location.latitude  ||= 0
      @report.location.longitude ||= 0
    end

    @open_locations       = [@report.location]
    @eliminated_locations = []
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports/3/eliminate

  # This action is used exclusively for eliminating an existing report.
  def eliminate
    # Parse the eliminated_at param or set to current time. Make sure to
    # remove the param from params[:report] to avoid updating it in update_attributes.
    eliminated_time = Time.zone.parse(params[:report][:eliminated_at]) if params[:report][:eliminated_at].present?
    eliminated_time = Time.zone.now if eliminated_time.blank?
    params[:report].delete(:eliminated_at)
    @report.eliminated_at = eliminated_time

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank?
      flash[:alert] = I18n.t("activerecord.attributes.report.after_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      redirect_to :back and return
    else
      filename  = @current_user.display_name.underscore + "_report.jpg"
      data      = prepare_base64_image_for_paperclip(base64_image, filename)
    end
    @report.after_photo = data
    params[:report].delete(:compressed_photo)

    if params[:report] && params[:report][:location_attributes]
      params[:report][:location_attributes].merge!(:neighborhood_id => @neighborhood.id)
    end

    @report.eliminator_id = @current_user.id
    if @report.update_attributes(params[:report])
      Analytics.track( :user_id => @current_user.id, :event => "Eliminated a report", :properties => {:neighborhood => @neighborhood.name} ) if Rails.env.production?

      # Let's award the user for submitting a report.
      @current_user.award_points_for_eliminating(@report)
      flash[:notice] = I18n.t("activerecord.success.report.eliminate")
      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(", ")
      redirect_to :back and return
    end
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports/3/prepare

  # This method is used exclusively to prepare a report that may not have
  # a breeding site or before photo present. This can occur if you create
  # reports from SMS or CSV.
  def prepare
    # TODO: Refactor this.
    if params[:report] && params[:report][:location_attributes]
      params[:report][:location_attributes].merge!(:neighborhood_id => @neighborhood.id)
    end

    address  = params[:report][:location_attributes].slice(:address)

    # Update the location.
    if @report.location.present?
      location = @report.location
      location.update_attributes(address)
    else
      # for whatever reason if location doesn't exist create a new one
      location = Location.find_or_create_by_address(address)
    end

    location.latitude        = params[:report][:location_attributes][:latitude] if params[:report][:location_attributes][:latitude].present?
    location.longitude       = params[:report][:location_attributes][:longitude] if params[:report][:location_attributes][:longitude].present?
    location.neighborhood_id = @neighborhood.id
    location.save

    @report.location_id  = location.id

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank?
      flash[:alert] = I18n.t("activerecord.attributes.report.after_photo") + " " + I18n.t("activerecord.errors.messages.blank")
      redirect_to :back and return
    else
      filename  = @current_user.display_name.underscore + "_report.jpg"
      data      = prepare_base64_image_for_paperclip(base64_image, filename)
    end

    # We set data on before_photo in this case since it come from an SMS,
    # which doesn't have an image.
    @report.before_photo    = data
    @report.neighborhood_id = @neighborhood.id

    # Verify report saves and form submission is valid
    if @report.update_attributes(params[:report])
      @report.update_column(:completed_at, Time.zone.now)

      # Let's award the user for submitting a report.
      @current_user.award_points_for_submitting(@report)

      # Decide where to redirect: if there are still incomplete reports,
      # then let's redirect to the first available one.
      incomplete_reports = @current_user.incomplete_reports
      if incomplete_reports.present?
        report = incomplete_reports.first
        flash[:notice] = I18n.t("views.reports.flashes.call_to_action_to_complete")
        redirect_to edit_neighborhood_report_path(@neighborhood, report) and return
      else
        flash[:notice] = I18n.t("activerecord.success.report.create")
        redirect_to neighborhood_reports_path(@neighborhood) and return
      end

    else
      flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(" ")
      redirect_to edit_neighborhood_report_path(@neighborhood) and return
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
    @report = Report.find(params[:id])

    if @report.location.blank?
      @report.location = Location.new
      @report.location.latitude  ||= 0
      @report.location.longitude ||= 0
    end
  end

  #----------------------------------------------------------------------------
  # PUT /neighborhoods/:neighborhood_id/reports/:id/verify

  def verify_report
    @report = Report.find(params[:id])
    if @report.location.blank?
      @report.location = Location.new
      @report.location.latitude  ||= 0
      @report.location.longitude ||= 0
    end

    @report.neighborhood_id = @neighborhood.id

    if params[:has_before_photo].blank?
      flash[:alert] = "You need to specify if the report has a before photo or not!"
      render "verify" and return
    end

    # Set the attr accessor on report to save with/without photo
    @report.save_without_before_photo = (params[:has_before_photo].to_i == 0)

    base64_image = params[:report][:compressed_photo]
    if base64_image.blank? && @report.save_without_before_photo != true
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
      @report.update_column(:completed_at, Time.zone.now)
      @report.update_column(:verified_at, Time.zone.now)

      # Let's award the user for submitting a report.
      @current_user.award_points_for_submitting(@report)

      redirect_to params[:redirect_path] || verify_csv_report_path(@report.csv_report) and return
    else
      render "verify" and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/:neighborhood_id/reports/problem
  # TODO: Right now, we're using isVerified column to define *validity*
  # The correct solution would be to deprecate both is_resolved_verified
  # and isVerified.
  def problem
    @report = Report.find(params[:id])

    # Now update the report.
    @report.isVerified  = "f"
    @report.verifier_id = @current_user.id
    @report.verified_at = Time.zone.now

    if @report.save(:validate => false)
      flash[:notice] = I18n.t("activerecord.success.report.verify")
      redirect_to neighborhood_reports_path(@neighborhood)
    else
      redirect_to :back and return
    end
  end

  #----------------------------------------------------------------------------
  #

  def torpedos
    @user = User.find(params[:id])
    @reports = @user.reports.sms.where('breeding_site_id IS NOT NULL')
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


  def creditar
    respond_to do |format|
      if @report.creditar
        format.js
      else
        format.json { render json: { message: "failure"}, status: 401 }
      end
    end
  end

  def credit
    respond_to do |format|
      if @report.credit
        format.js
      else
        format.json { render json: {message: "failure"}, status: 401}
      end
    end
  end

  def discredit
    respond_to do |format|
      if @report.discredit
        format.js
      else
        format.json { render json: {message: "failure"}, status: 401}
      end
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def find_by_id
    @report = Report.find(params[:id])
  end

  #----------------------------------------------------------------------------

  def ensure_coordinator
    redirect_to neighborhood_reports_path(@neighborhood) unless @current_user && @current_user.coordinator?
  end

  #----------------------------------------------------------------------------

end
