#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController
  before_filter :require_login,             :except => [:index, :verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id,                :only   => [:update, :creditar, :credit, :discredit, :like, :comment]
  before_filter :ensure_team_chosen,        :only   => [:index]
  before_filter :redirect_if_incomplete_reports, :only => [:index]

  #----------------------------------------------------------------------------

  def index
    @reports = Report.includes(:likes, :location).where(:neighborhood_id => @neighborhood.id).order("created_at DESC")
    @report_count  = @reports.count
    @report_limit  = 10
    @report_offset = (params[:page] || 0).to_i * @report_limit

    # Remove report that incurred an error, it should be at the top already
    @reports = @reports.limit(@report_limit).offset(@report_offset)
    @reports.reject!{ |r| r.before_photo.blank? }

    # Generate the different types of locations based on report.
    # TODO: This iteration should be done in SQL!
    @open_locations       = []
    @eliminated_locations = []
    @reports.each do |report|
      # In the case that the location is missing, then let's skip it.
      next if report.location.nil?

      # TODO: Why the !!! are we using two types of columns to encode
      # the same information (open versus eliminated). Get rid of one or the other.
      if report.open?
        @open_locations << report.location
      elsif report.eliminated?
        @eliminated_locations << report.location
      else
        @open_locations << report.location
      end
    end

    @open_locations.compact!
    @eliminated_locations.compact!
  end

  #----------------------------------------------------------------------------

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

    @report = Report.new(params[:report])
    @report.reporter_id  = @current_user.id
    @report.neighborhood_id = @neighborhood.id
    @report.completed_at = Time.now

    if @report.save
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

    if @report.location.blank?
      @report.location = Location.new
      @report.location.latitude  ||= 0
      @report.location.longitude ||= 0
    end

    @open_locations       = [@report.location]
    @eliminated_locations = []
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports

  def update
    address = params[:report][:location_attributes].slice(:street_name,:street_number,:street_type)
    address.each{ |k,v| address[k] = v.downcase.titleize}

    # Update the location.
    if @report.location
      location = @report.location
      location.update_attributes(address)
    else
      # for whatever reason if location doesn't exist create a new one
      location = Location.find_or_create_by_street_type_and_street_name_and_street_number(address)
    end

    location.latitude     = params[:report][:location_attributes][:latitude] if params[:report][:location_attributes][:latitude].present?
    location.longitude    = params[:report][:location_attributes][:longitude] if params[:report][:location_attributes][:longitude].present?
    location.neighborhood_id = @neighborhood.id
    location.save

    @report.location_id  = location.id

    # Update SMS
    if @report.incomplete?

      # Verify report saves and form submission is valid
      if @report.update_attributes(params[:report])
        flash[:notice] = I18n.t("activerecord.success.report.create")

        @report.neighborhood_id = @neighborhood.id
        @report.completed_at    = Time.now
        @report.save(:validate => false)

        # Let's award the user for submitting a report.
        # @current_user.award_points_for_submitting(@report)

        redirect_to neighborhood_reports_path(@neighborhood) and return

      # Error occurred when completing SMS report
      else
        flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(" ")
        redirect_to edit_neighborhood_report_path(@neighborhood, {:report => params[:report]}) and return
      end
    end

    if @report.update_attributes(params[:report])
      @report.update_attributes(:eliminated_at => Time.now, :neighborhood_id => @neighborhood.id, :eliminator_id => @current_user.id)

      # Let's award the user for submitting a report.
      @current_user.award_points_for_eliminating(@report)


      flash[:notice] = I18n.t("activerecord.success.report.eliminate")
      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(", ")
      redirect_to :back and return
    end
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
      redirect_to :back, :notice => I18n.t("activerecord.success.comment.create") and return
    else
      redirect_to :back, :alert => I18n.t("attributes.content") + " " + I18n.t("activerecord.errors.comments.blank") and return
    end
  end

  #----------------------------------------------------------------------------

  def destroy
    if @current_user.coordinator? or @current_user.created_reports.find_by_id(params[:id])
      @report = Report.find(params[:id])
      @report.destroy
      flash[:notice] = I18n.t("activerecord.success.report.delete")
    end

    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/:neighborhood_id/reports/verify

  def verify
    @report = Report.find(params[:id])

    @report.isVerified  = "t"
    @report.verifier_id = @current_user.id
    @report.verified_at = Time.now

    if @report.save(:validate => false)
      @current_user.award_points_for_verifying(@report)

      flash[:notice] = I18n.t("activerecord.success.report.verify")
      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      redirect_to :back and return
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
    @report.verified_at = Time.now

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
    @reports = @user.reports.sms.where('elimination_type IS NOT NULL')
  end

  #----------------------------------------------------------------------------
  # POST /reports/gateway
  # This is the path to which SMSBroadcastReceiver.java posts to when
  # the SMSGateway receives an SMS. It expects a JSON response which it
  # will display on the phone as a Toast (see
  # http://developer.android.com/reference/android/widget/Toast.html for more).
  def gateway
    # Verify phone number minimum length and placeholder, otherwise ignore
    if params[:from] == User::PHONE_NUMBER_PLACEHOLDER || params[:from].to_s.length < User::MIN_PHONE_LENGTH
      render :nothing => true, :status => 400 and return
    end

    # Now let's try to identify the user.
    user = User.find_by_phone_number(params[:from]) if params[:from].present?
    if user.nil?
      Notification.create(board: "5521981865344", phone: params[:from], text: "Você ainda não tem uma conta. Registre-se no site do Dengue Torpedo.")
      render :json => { message: "There is no registered user with the given phone number." }, :status => 404 and return
    end

    # At this point, we're guaranteed for the user to exist.
    # Now, check if user is morador, admin, or coordenador. If they are,
    # then they're setup for SMS. Otherwise, they're not.
    if user.residents?
      @report = user.build_report_via_sms(params)

      # NOTE: We will not award points here because we do this in ReportsController#update.
      if @report.save!
        Notification.create(board: "5521981865344", phone: params[:from], text: "Parabéns! O seu relato foi recebido e adicionado ao Dengue Torpedo.")
        render :json => { message: "success", report: @report}
      else
        Notification.create(board: "5521981865344", phone: params[:from], text: "Nós não pudemos adicionar o seu relato porque houve um erro no nosso sistema.")
        render :json => { message: @report.errors.full_messages }, :status => 401
      end
    else
      Notification.create(board: "5521981865344", phone: params[:from], text: "O seu perfil não está habilitado para o envio do Dengue Torpedo.")
      render :json => { message: "Sponsors or verifiers" }, :status => 401
    end
  end

  #----------------------------------------------------------------------------
  # GET /reports/notifications
  # This is used by SMSGateway to fetch the latest notifications created in
  # the 'gateway' action that will be sent out as SMS.

  def notifications
    @notifications = Notification.where(:read => false)
    @notifications.each do |notification|
      notification.read = true
      notification.save
    end

    render :json => @notifications and return
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

  def redirect_if_incomplete_reports
    # We want to redirect only if user is viewing their own neighborhood.
    return unless @neighborhood == @current_user.neighborhood

    @report = @current_user.reports.order("created_at ASC").find {|r| r.incomplete?}
    flash.keep
    redirect_to edit_neighborhood_report_path(@neighborhood, @report) and return if @report.present?
  end

  #----------------------------------------------------------------------------

end
