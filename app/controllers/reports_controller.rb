#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController
  before_filter :require_login, :except => [:index, :verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id,    :only   => [:update, :creditar, :credit, :discredit]
  before_filter :require_admin, :only   => [:types]

  #----------------------------------------------------------------------------

  def types
    @types   = EliminationType.all
    @methods = EliminationMethod.all
  end

  #----------------------------------------------------------------------------

  def index
    @new_report          = Report.new(params[:new_report])
    @new_report_location = Location.find_by_id(params[:location]) || Location.new

    # We display the reports in the following order:
    # 1. Reports that incurred an error when attempting to be eliminated
    # 2. Incomplete SMS reports
    # 3. All created reports (aka, the misleading column completed_at is not nil)
    @reports = []
    #1.
    error_report = Report.find_by_id(params[:report])

    if error_report
      # TODO : URL is messy when using params, possibly change to id when EliminationMethod implemented
      error_report.elimination_method = params[:elimination_method]
      @reports += [ error_report ]
    end

    #2.
    @reports += current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a if current_user

    #3.
    @reports += Report.where(:neighborhood_id => @neighborhood.id).select(&:completed_at).sort_by(&:completed_at).reverse

    # Remove report that incurred an error, it should be at the top already
    @reports.reject!{|r| r == params[:report]}

    # Generate the different types of locations based on report.
    # TODO: This iteration should be done in SQL!
    @open_locations       = []
    @eliminated_locations = []
    @reports.each do |report|
      next unless (report.reporter == current_user || report.elimination_type)

      # In the case that the location is missing, then let's skip it.
      next if report.location.nil?

      # TODO: Why the !!! are we using two types of columns to encode
      # the same information (open versus eliminated). Get rid of one or the other.
      if report.status == Report::STATUS[:reported]
        @open_locations << report.location
      elsif report.status == Report::STATUS[:eliminated]
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

    # If location was previously created, use that
    # TODO @awdorsett: The new refactoring will make this fail. Let's move away
    # from usage of session.

    saved_location = Location.find_by_id(session[:location_id])
    location_attributes = params[:report][:location_attributes]

    if saved_location
      location = saved_location
    else
      # Find the location based on user's input (street type, name, number) and
      # ESRI's geolocation (latitude, longitude).
      # When the user inputs an address into the textfields, we trigger an ESRI
      # map search on the associated map that updates the x and y hidden fields
      # in the form. In the case that the map is unavailable (or JS is disabled),
      # an after_commit hook into the Location model will trigger a background
      # worker to fetch the map coordinates.

      location = Location.find_or_create_by_street_type_and_street_name_and_street_number(
        location_attributes[:street_type].downcase.titleize,
        location_attributes[:street_name].downcase.titleize,
        location_attributes[:street_number].downcase.titleize
      )

      location.latitude     = location_attributes[:latitude]
      location.longitude    = location_attributes[:longitude]
      location.neighborhood = @neighborhood
      location.save
    end

    @report              = Report.new(params[:report])
    @report.reporter_id  = @current_user.id
    @report.neighborhood_id = @neighborhood.id
    @report.status       = Report::STATUS[:reported]
    @report.location_id  = location.id
    @report.completed_at = Time.now


    # TODO seperated this from if statement in order to add all errors to flash[:alert], better way?
    valid_address = validate_address(location_attributes,@report)

    # Now let's save the report.
    if @report.save && valid_address
      flash[:should_render_social_media_buttons] = true
      flash[:notice] = I18n.t("activerecord.success.report.create")

      redirect_to neighborhood_reports_path(@neighborhood) and return

    else
      flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(", ")

      redirect_to neighborhood_reports_path(@neighborhood,
        :params => {:new_report => params[:report].except(:before_photo), :location => location.id}) and return
    end

  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports/1/edit

  def edit
    @new_report = @current_user.created_reports.find(params[:id])

    if @new_report.location
      @new_report.location.latitude  ||= 0
      @new_report.location.longitude ||= 0
    end

    # saved_params will exist if an error occurred and the user was redirect to the edit page
    if params[:report].present?
      @new_report.elimination_type = params[:report][:elimination_type]
      @new_report.report =  params[:report][:report]
    end

  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports

  def update
    submission_points = 50

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
    location.neighborhood = @neighborhood
    location.save

    @report.location_id  = location.id

    # Update SMS
    if @report.sms_incomplete?

      # Verify report saves and form submission is valid
      if @report.update_attributes(params[:report])
        flash[:notice] = I18n.t("activerecord.success.report.create")

        @report.status          = Report::STATUS[:reported]
        @report.neighborhood_id = @neighborhood.id
        @report.completed_at    = Time.now
        @report.save

        redirect_to neighborhood_reports_path(@neighborhood) and return

      # Error occurred when completing SMS report
      else
        flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(" ")
        redirect_to edit_neighborhood_report_path(@neighborhood, {:report => params[:report]}) and return
      end
    end


    # Update web report
    if @report.update_attributes(params[:report])
      @current_user.update_attribute(:points, @current_user.points + submission_points)
      @current_user.update_attribute(:total_points, @current_user.total_points + submission_points)

      flash[:notice] = I18n.t("activerecord.success.report.eliminate")
      @report.touch(:eliminated_at)
      @report.update_attribute(:status, Report::STATUS[:eliminated])
      @report.update_attribute(:neighborhood_id, @neighborhood.id)
      @report.update_attribute(:eliminator_id, @current_user.id)
      award_points @report, @current_user

      redirect_to neighborhood_reports_path(@neighborhood) and return

    # Error occurred updating attributes
    else
      flash[:alert] = flash[:alert].to_s + @report.errors.full_messages.join(" ")

      redirect_to neighborhood_reports_path(@neighborhood,
        :params=>{:report => @report.id, :elimination_method => params[:report][:elimination_method]}) and return
    end
  end

  #----------------------------------------------------------------------------

  def destroy
    if @current_user.admin? or @current_user.created_reports.find_by_id(params[:id])
      @report = Report.find(params[:id])
      @report.deduct_points
      @report.destroy
      flash[:notice] = I18n.t("activerecord.success.report.delete")
    end

    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------

  def verify
    @report = Report.find(params[:id])

    if @report.status == Report::STATUS[:eliminated]
      @report.is_resolved_verified = true
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now

    elsif @report.status == Report::STATUS[:reported]
      @report.isVerified = true
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
    end

    @report.verifier_name = @current_user.display_name

    if @report.save(:validate => false)
      @current_user.points += 50
      @current_user.total_points += 50
      @current_user.save
      flash[:notice] = I18n.t("activerecord.success.report.verify")
      redirect_to neighborhood_reports_path(@neighborhood)
    else
      redirect_to :back
    end
  end

  #----------------------------------------------------------------------------

  def problem
    @report = Report.find(params[:id])

    if @report.is_eliminated?
      @report.is_resolved_verified = false
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now
      @report.resolved_verifier.points -= 100
      @report.resolved_verifier.save
    elsif @report.is_open?
      @report.isVerified = false
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
      @report.verifier.points -= 100
      @report.verifier.save
    end

    if @report.save(:validate => false)
      flash[:notice] = I18n.t("activerecord.success.report.verify")
      redirect_to neighborhood_reports_path(@neighborhood)
    else
      redirect_to :back
    end
  end

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

  def award_points report, user
    if report.elimination_method.present?
      points = EliminationMethod.find_by_method(report.elimination_method).points
      user.points += points
      user.total_points += points
      user.save
    end
  end

  #----------------------------------------------------------------------------

  def validate_address(location_params, report)
    if (location_params[:street_name].blank? && report.location.street_name.blank?) ||
       (location_params[:street_type].blank? && report.location.street_type.blank?) ||
       (location_params[:street_number].blank? && report.location.street_number.blank?)

        flash[:alert] = flash[:alert].to_s + " " + I18n.t("report.form.fill_in_complete_address")
        return false
    end

    return true
  end

  #----------------------------------------------------------------------------

end
