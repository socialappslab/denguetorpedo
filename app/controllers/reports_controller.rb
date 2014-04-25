#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController
  before_filter :require_login, :except => [:verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id,    :only   => [:update, :creditar, :credit, :discredit]
  before_filter :require_admin, :only   => [:types]

  #----------------------------------------------------------------------------

  def types
    @types   = EliminationType.all
    @methods = EliminationMethod.all
  end

  #----------------------------------------------------------------------------

  def index
    @new_report          = Report.new( params[:report] )
    @new_report_location = Location.find_by_id(session[:location_id]) || Location.new

    # TODO: Deprecate EliminationMethods in favor for EliminationMethod.
    # TODO: This should not be an instance variable since we're only using
    # it for select form tag.
    @points = EliminationMethods.points

    # We display the reports in the following order:
    # 1. Unfinished report in the middle of being created,
    # 1. Logged-in user's reports,
    # 2. All created reports (aka, the misleading column completed_at is not nil)
    @reports = []
    @reports += [ Report.find_by_id(session[:saved_report_id]) ] if session[:saved_report_id].present?
    @reports += current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a

    # TODO: Do we actually want to display reports that have completed_at column nil?
    # Better alternative: @reports += Report.where("completed_at is NOT NULL").where("id != ?", session[:saved_report_id]).order("completed_at DESC").to_a
    @reports += Report.where(:neighborhood_id => @neighborhood.id).select(&:completed_at).reject{|r| r.id == session[:saved_report_id]}.sort_by(&:completed_at).reverse

    # Reset the session variables
    session[:saved_report_id] = nil
    session[:report]          = nil
    session[:location_id]     = nil

    # Generate the different types of locations based on report.
    # TODO: This iteration should be done in SQL!
    reports_with_status_filtered = []
    locations                    = []
    open_locations               = []
    eliminated_locations         = []
    @reports.each do |report|
      next unless (report.reporter == current_user || report.elimination_type)

      # Add report to list of filtered status reports.
      # TODO: Do we really need to do this.
      reports_with_status_filtered << report

      # In the case that the location is missing, then let's skip it.
      next if report.location.nil?

      # TODO: Why the !!! are we using two types of columns to encode
      # the same information (open versus eliminated). Get rid of one or the other.
      if report.status == :reported
        open_locations << report.location
      elsif report.status == :eliminated
        eliminated_locations << report.location
      else
        if report.status_cd == 1
          eliminated_locations << report.location
        else
          open_locations << report.location
        end
      end

      locations << report.location
    end

    # Generate markers from the different types of locations.
    @markers            = locations.map            { |location| location.info}
    @open_markers       = open_locations.map       { |location| location.info}
    @eliminated_markers = eliminated_locations.map { |location| location.info}
    @locations = locations


    # TODO @awdorsett - Does this affect anything? possibly used when you chose elimination type afterwards
    #@reports = reports_with_status_filtered
    # TODO: These counts should be tied to the SQL query we're running to fetch the reports (see above)
    @counts            = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).group(:location_id).count
    @open_counts       = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 0).group(:location_id).count
    @eliminated_counts = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 1).group(:location_id).count

    # TODO: What? How is open reports equal to eliminated reports?
    @open_feed         = @reports
    @eliminate_feed    = @reports
  end

  #----------------------------------------------------------------------------

  def new
    @report = Report.new
  end

  #-----------------------------------------------------------------------------
  # POST /neighborhoods/1/reports
  #  {"utf8"=>"✓",
  # "authenticity_token"=>"94xRwimaBHn1i38ncPFUUODc8OaMuy1A00Qy7qtT36E=",
  # "error"=>"false",
  # "report_id"=>"",
  # "report"=>{"location_attributes"=>{"street_type"=>"Rua",
  # "street_name"=>"Tatajuba",
  # "street_number"=>"50",
  # "latitude"=>"",
  # "longitude"=>""},
  # "report"=>"",
  # "elimination_type"=>""},
  # "commit"=>"Enviar!",
  # "neighborhood_id"=>"7"}

  def create
    # If location was previously created, use that
    # TODO @awdorsett: The new refactoring will make this fail. Let's move away
    # from usage of session.
    saved_location = Location.find_by_id(session[:location_id])

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
        params[:report][:location_attributes][:street_type].downcase.titleize,
        params[:report][:location_attributes][:street_name].downcase.titleize,
        params[:report][:location_attributes][:street_number].downcase.titleize
      )

      location.latitude     = params[:report][:location_attributes][:latitude]
      location.longitude    = params[:report][:location_attributes][:longitude]
      location.neighborhood = @neighborhood
      location.save
    end

    # TODO @dman7: why is status (type int) but is assigned a symbol?
    @report                 = Report.new(params[:report])
    @report.neighborhood_id = @neighborhood.id
    @report.status          = :reported
    @report.location_id     = location.id
    @report.completed_at    = Time.now

    # Now let's save the report.
    if validate_report_submission(params, @report) && @report.save
      session[:report]      = nil
      session[:location_id] = nil

      flash[:notice] = 'Foco marcado com sucesso!'
      redirect_to neighborhood_reports_path(@neighborhood) and return
    end

    # Before photo too large for session
    session[:report]      = params[:report].except(:before_photo)
    session[:location_id] = location.id

    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports/1/edit

  def edit
    @new_report = @current_user.created_reports.find(params[:id])
    @new_report.location.latitude  ||= 0
    @new_report.location.longitude ||= 0
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports
  # {"utf8"=>"✓",
  #  "_method"=>"put",
  #  "authenticity_token"=>"94xRwimaBHn1i38ncPFUUODc8OaMuy1A00Qy7qtT36E=",
  #  "error"=>"false",
  #  "report"=>{"reporter_id"=>"13",
  #  "location_attributes"=>{"street_type"=>"",
  #  "street_name"=>"",
  #  "street_number"=>"",
  #  "latitude"=>"0.0",
  #  "longitude"=>"0.0",
  #  "id"=>"38"},
  #  "report"=>"This is a report",
  #  "elimination_type"=>""},
  #  "commit"=>"Enviar!",
  #  "neighborhood_id"=>"7",
  #  "id"=>"38"}

  def update
    submission_points = 50

    # Update the location.
    location_params = params[:report][:location_attributes].slice(:street_name,:street_number,:street_type)

    # Location should have been created when user sends SMS
    if @report.location
      location = @report.location
      location.update_attributes(location_params)
    else
      # for whatever reason if location doesn't exist create a new one
      location = Location.find_or_create_by_street_type_and_street_name_and_street_number(
          params[:report][:location_attributes][:street_type].downcase.titleize,
          params[:report][:location_attributes][:street_name].downcase.titleize,
          params[:report][:location_attributes][:street_number].downcase.titleize
      )
    end

    location.latitude     = params[:report][:location_attributes][:latitude] if params[:report][:location_attributes][:latitude].present?
    location.longitude    = params[:report][:location_attributes][:longitude] if params[:report][:location_attributes][:longitude].present?
    location.neighborhood = @neighborhood
    location.save

    @report.location_id  = location.id

    if @report.sms_incomplete?
      # Verify report saves and form submission is valid
      if @report.update_attributes(params[:report]) && validate_report_submission(params, @report)
        flash[:notice] = 'Foco marcado com sucesso!'

        @report.status          = :reported   # TODO can't mass assign, is that by design?
        @report.neighborhood_id = @neighborhood.id
        @report.completed_at    = Time.now
        @report.save

        redirect_to neighborhood_reports_path(@neighborhood) and return
      else
        redirect_to edit_neighborhood_report_path(@neighborhood, @report) and return
      end
    end  # End of report creation from SMS


    session[:saved_report_id] = @report.id

    if @report.update_attributes(params[:report]) && validate_report_elimination_submission(params, @report)
      @current_user.update_attribute(:points, @current_user.points + submission_points)
      @current_user.update_attribute(:total_points, @current_user.total_points + submission_points)

      flash[:notice] = "Você eliminou o foco!"
      @report.update_attribute(:completed_at, Time.now)
      @report.touch(:eliminated_at)
      @report.update_attribute(:status_cd, 1)
      @report.update_attribute(:neighborhood_id, @neighborhood.id)
      @report.update_attribute(:eliminator_id, @current_user.id)
      award_points @report, @current_user

      redirect_to neighborhood_reports_path(@neighborhood) and return
    else
      redirect_to edit_neighborhood_report_path(@neighborhood, @report) and return
    end

    # @report.save

    # if every part of the report submission is complete, submit_complete = true
    # if submit_complete
    #   flash[:notice] = "Você eliminou o foco!"
    #   @report.touch(:eliminated_at)
    #   @report.update_attribute(:status_cd, 1)
    #   @report.update_attribute(:eliminator_id, @current_user.id)
    #   award_points @report, @current_user
    # end

    # save the report so you can access it in index for errors and completions
  end

  def destroy
    if @current_user.admin? or @current_user.created_reports.find_by_id(params[:id])
      @report = Report.find(params[:id])
      @report.deduct_points
      @report.destroy
      flash[:notice] = "Foco deletado com sucesso."
    end

    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  def verify
    @report = Report.find(params[:id])

    if @report.status_cd == 1
      @report.is_resolved_verified = true
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now

    elsif @report.status_cd == 0
      @report.isVerified = true
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
    end

    @report.verifier_name = @current_user.display_name

    if @report.save

      @current_user.points += 50
      @current_user.total_points += 50
      @current_user.save
      flash[:notice] = "O foco foi verificado."
      redirect_to neighborhood_reports_path(@neighborhood)
    else
      redirect_to :back
    end
  end

  def problem
    @report = Report.find(params[:id])

    if @report.status_cd == 1
      @report.is_resolved_verified = false
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now
      @report.resolved_verifier.points -= 100
      @report.resolved_verifier.save
    elsif @report.status_cd == 0
      @report.isVerified = false
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
      @report.verifier.points -= 100
      @report.verifier.save
    end
    if @report.save
      flash[:notice] = "O foco foi verificado."
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
    puts "params: #{params}"
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

  # Tests for the existence of report description ("report"), before_photo,
  # elimination type, street type, street name, and street number
  #
  # Returns true if complete, else returns false with flash[:alert] filled
  # TODO @awdorsett: Some of these things, such as the :report and :before_photo could cleverly
  # become model validations (e.g. validates :report, :presence => true). If you
  # end up doing it, remember to make sure that report creation via SMS still works.
  def validate_report_submission params, report
    # If no report was filled out, then ask them to fill it out.
    if params[:report][:report] == ""
      flash[:alert] = flash[:alert].to_s + " Você tem que descrever o local e/ou o foco."
      return false
    end

    # User has created initial report but now needs to select an elimination type
    if params[:report][:elimination_type].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que escolher um tipo de foco."
      return false
    end

    # If there was no before photograph, then ask them to upload it.
    if params[:report][:before_photo].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco encontrado."
      return false
    end

    # If address is not completely filled out
    if (params[:report][:location_attributes][:street_name].blank? && report.location.street_name.blank?) ||
        (params[:report][:location_attributes][:street_number].blank? && report.location.street_number.blank?) ||
        (params[:report][:location_attributes][:street_type].blank? && report.location.street_type.blank?)
      # TODO Placeholder translated via Google Translate. "You must submit the entire address."
      flash[:alert] = flash[:alert].to_s + " Você deve enviar o endereço completo."
      return false
    end

    return true
  end

  #----------------------------------------------------------------------------

  def validate_report_elimination_submission(params, report)
    if params[:report][:after_photo].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco eliminado."
      return false
    end

    # Check to see if user has selected a method of elimination
    if params[:report][:elimination_method].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que escolher um método de eliminação."
      return false
    end

    return true
  end

  #----------------------------------------------------------------------------

end
