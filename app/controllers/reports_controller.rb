#!/bin/env ruby
# encoding: utf-8

class ReportsController < NeighborhoodsBaseController

  before_filter :require_login, :except => [:verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id, only: [:creditar, :credit, :discredit]
  before_filter :require_admin, :only =>[:types]

  #points user receives for submitting a site

  def types
    @types = EliminationType.all
    @methods = EliminationMethod.all
  end

  def index
    @current_report = params[:report]
    @current_user != nil ? @highlightReportItem = "nav_highlight" : @highlightReportItem = ""

    # new report form attributes
    # use existing params if error occured during create
    report_params = session[:params][:report] if session[:params]

    # if report_params is present an error occurred during create, triggers showing new report tab in view
    @create_error = report_params.present?

    @new_report = Report.new(report_params)
    @new_report_location = Location.find_by_id(session[:location_id]) || Location.new

    @elimination_types = EliminationType.pluck(:name)

    session[:params] = nil
    session[:location_id] = nil

    @elimination_method_select = EliminationMethods.field_select

    reports_with_status_filtered = []
    locations                    = []
    open_locations               = []
    eliminated_locations         = []

    @points = EliminationMethods.points
    # TODO @awdorsett - the first Report all may not be needed, is it for SMS or elim type selection?

    # We only want to display the following reports:
    # 1. Logged-in user's reports, localized to the viewed neighborhood,
    # 2. All created reports (the misleading column completed_at is not nil)
    # @reports = Report.all.reject(&:completed_at).sort_by(&:created_at).reverse
    # @reports = Report.joins(:location).where("locations.neighborhood_id = ?", @neighborhood.id)
    @reports = current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a
    @reports += Report.select(&:completed_at).reject{|r| r.id == session[:saved_report]}.sort_by(&:completed_at).reverse
    @reports = @reports.find_all {|r| r.location.neighborhood_id == @neighborhood.id }

    # if report has been completed or has an error during update
    # TODO @awdorsett - more effecient way?
    if session[:saved_report]
      @reports = [Report.find_by_id(session[:saved_report])] + @reports
      session[:saved_report] = nil
    end

    # This should be what populates the markers for map
    # TODO @awdorsett - refactor this
    @reports.each do |report|
      if (report.reporter == @current_user or report.elimination_type)
        if report.status == :reported
          reports_with_status_filtered << report
          open_locations << report.location
        elsif report.status == :eliminated
          reports_with_status_filtered << report
          eliminated_locations << report.location
        else
            reports_with_status_filtered << report
            if report.status_cd == 1
              eliminated_locations << report.location
            else
              open_locations << report.location
            end

        end

        locations << report.location
      end

    end

    @markers = locations.compact.map { |location| location.info}
    @open_markers = open_locations.compact.map { |location| location.info}
    @eliminated_markers = eliminated_locations.compact.map { |location| location.info}

    # TODO @awdorsett - Does this affect anything? possibly used when you chose elimination type afterwards
    #@reports = reports_with_status_filtered
    # TODO: These counts should be tied to the SQL query we're running to fetch the reports (see above)
    @counts = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).group(:location_id).count
    @open_counts = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 0).group(:location_id).count
    @eliminated_counts = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 1).group(:location_id).count
    @open_feed = @reports
    @eliminate_feed = @reports
  end

  def new
    @report = Report.new
  end


  #-----------------------------------------------------------------------------
  # POST /reports?html%5Bautocomplete%5D=off&html%5Bmultipart%5D=true

  def create
    # used to handle errors, if error occurs then set to false
    create_complete = true

    # If location was previously created, use that
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
        params[:street_type].downcase.titleize,
        params[:street_name].downcase.titleize,
        params[:street_number].downcase.titleize
      )

      location.latitude  = params[:x] if params[:x].present?
      location.longitude = params[:y] if params[:y].present?
      location.neighborhood = Neighborhood.find(params[:neighborhood_id]) if location.neighborhood.blank?

      location.save
    end


    @report              = Report.new(params[:report])
    @report.reporter_id  = @current_user.id
    @report.location_id  = location.id
    @report.status       = :reported # TODO @dman7: why is status (type int) but is assigned a symbol?
    @report.report       = params[:report][:report] # TODO: Not really needed. ensure that it's already there.
    @report.completed_at = Time.now
    @report.before_photo = params[:report][:before_photo]

    # If no report was filled out, then ask them to fill it out.
    if params[:report][:report] == ""
      flash[:alert] = flash[:alert].to_s + " Você tem que descrever o local e/ou o foco."
      create_complete = false
    end

    # If there was no before photograph, then ask them to upload it.
    if params[:report][:before_photo].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco encontrado."
      create_complete = false
    end

    # Now let's save the report.
    if create_complete && @report.save
      flash[:notice] = 'Foco marcado com sucesso!'
      redirect_to :action => 'index' and return
    end

    # Before photo too large for session
    params[:report].delete(:before_photo)

    session[:params] = params
    session[:location_id] = location.id

    redirect_to :back and return

  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/edit

  def edit

    report_id = session[:id] || params[:id]

    @new_report = @current_user.created_reports.find(report_id)

    @new_report_location = Location.find_by_id(@new_report.location.id)
    @new_report.location.latitude ||= 0
    @new_report.location.longitude ||= 0

    @elimination_types = EliminationType.pluck(:name)

  end

  #-----------------------------------------------------------------------------

  def update

    submission_points = 50
    submit_complete = true

    if request.put?
      @report = Report.find_by_id(params[:report_id])

      if @report.sms_incomplete?

        location_params = params.slice(:street_name,:street_number,:street_type)

        # Location should have been created when user sends SMS
        if @report.location
          location = @report.location
          location.update_attributes(location_params)
        else
          # for whatever reason if location doesn't exist create a new one
          location = Location.find_or_create_by_street_type_and_street_name_and_street_number(
              params[:street_type].downcase.titleize,
              params[:street_name].downcase.titleize,
              params[:street_number].downcase.titleize
          )
        end

        location.latitude  = params[:x] if params[:x].present?
        location.longitude = params[:y] if params[:y].present?
        location.neighborhood = Neighborhood.find(params[:neighborhood_id]) if location.neighborhood.blank?

        location.save

        @report.update_attributes(params[:report])
        @report.reporter_id  = @current_user.id
        @report.location_id  = location.id
        @report.status       = :reported
        @report.before_photo = params[:report][:before_photo]


        # Verify report saves and form submission is valid
        if @report.save && validate_report_submission(params, @report)
          flash[:notice] = 'Foco marcado com sucesso!'
          @report.update_attribute(:completed_at, Time.now)

          session.delete(:id)
          redirect_to :action => 'index' and return
        end


        session[:id] = @report.id
        redirect_to :back and return

      end  # End of report creation from SMS



      #@report = Report.find(params[:report_id])

      ## User pressed submit without selecting a elimination type
      #if params[:elimination_type].blank? and @report.elimination_type.blank?
      #  flash[:notice] = "Você tem que escolher um tipo de foco."
      #  submit_complete = false
      #  #redirect_to :back
      #  #return
      #end

      # User has created initial report but now needs to select an elimination type
      if @report.elimination_type.nil?
        if params[:elimination_type].present?
          @report.elimination_type = params[:elimination_type]
          @report.completed_at = Time.now
          @report.save

          flash[:notice] = "Tipo de foco atualizado com sucesso."  #Focus type updated successfully.

          @current_user.update_attribute(:points, @current_user.points + submission_points)
          @current_user.update_attribute(:total_points, @current_user.total_points + submission_points)

          redirect_to :back and return
        else
          # user must select an elimination type before proceeding
          flash[:alert] = "Você tem que escolher um tipo de foco." #You have to choose a type of focus.
          redirect_to :back and return
        end
      end


      if params[:report_description]
        @report.report = params[:report_description]
      end


      #if !params[:eliminate] and @report.after_photo_file_size.nil?
      #  flash[:error] = 'Você tem que carregar uma foto do foco eliminado.'
      #  redirect_to(:back)
      #  return
      #end


      # Check to see if user has selected a method of elimination
      if params[:selected_elimination_method].blank? && @report.elimination_method.blank?
        flash[:alert] = "Você tem que escolher um método de eliminação."  # You have to choose a method of disposal.
        submit_complete = false
      else
        #if user has updated the method then replace it
        if params[:selected_elimination_method].present?
          @report.elimination_method = params[:selected_elimination_method]
        end
      end

      # Check to see if user has uploaded "after" photo
      if @report.after_photo_file_size.nil?
        if params[:eliminate] && params[:eliminate][:after_photo] != nil
          @report.after_photo = params[:eliminate][:after_photo]
        else
          #user did not upload a photo
          flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco eliminado." #You have to upload a photo of focus eliminated
          submit_complete = false
        end
      end

      # Check if a location lon/lat exists
      # TODO @awdorsett check if error message is correct in portuguese
        if @report.location.latitude.blank? || @report.location.longitude.blank?
          if params[:latitude].present? || params[:longitude].present?
            # TODO @awdorsett find out why location doesn't save when report.save is called
            @report.location.latitude = params[:latitude]
            @report.location.longitude = params[:longitude]
            @report.location.save
          #else
          #  flash[:notice] = flash[:notice].to_s + ' Você tem que selecionar um local no mapa' #You have to select a location on the map
          #  submit_complete = false
          end
        end


      # ? If the eliminate form isn't being submitted
      # ? Not sure when this occurs
      # ? Maybe when submitting a new site
      #if !params[:eliminate]
      #  @report.update_attribute(:status_cd, 1)
      #  @report.update_attribute(:eliminator_id, @current_user.id)
      #  # @report.elimination_type = params[:elimination_type]
      #  @report.elimination_method = params[:selected_elimination_method]
      #  @report.touch(:eliminated_at)
      #  @report.save
      #  flash[:notice] = "Você eliminou o foco!1"
      #  redirect_to neighborhood_reports_path(@neighborhood)
      #  return
      #end

      @report.save

      # if every part of the report submission is complete, submit_complete = true
      if submit_complete
        flash[:notice] = "Você eliminou o foco!"
        @report.touch(:eliminated_at)
        @report.update_attribute(:status_cd, 1)
        @report.update_attribute(:eliminator_id, @current_user.id)
        award_points @report, @current_user
      end

      # save the report so you can access it in index for errors and completions
      session[:saved_report]= @report.id
      redirect_to :back


      ## Submitting an after photo
      #if params[:eliminate][:after_photo] != nil
      #  # user uploaded an after photo
      #  begin
      #    @report.after_photo = params[:eliminate][:after_photo]
      #    @report.update_attribute(:status_cd, 1)
      #    @report.update_attribute(:eliminator_id, @current_user.id)
      #    @report.touch(:eliminated_at)
      #    @current_user.points += 3
      #    @current_user.save
      #
      #  rescue
      #    flash[:notice] = 'An error has occurred!'
      #    redirect_to(:back)
      #    return
      #  end

        # @report.elimination_type = EliminationMethods.getEliminationTypeFromMethodSelect(params["method_of_elimination"])
        # @report.elimination_method = params["method_of_elimination"]
        # @report.elimination_type = params[:elimination_type]
        #@report.elimination_method = params[:selected_elimination_method]

        #if @report.save
        #  flash[:notice] = 'Você eliminou o foco!'
        #  redirect_to(:back)
        #else
        #  #for some reason save causes error here, but in view it looks OK
        #  flash[:notice] = 'An error has occurred'
        #  redirect_to(:back)
        #end
      #
      #elsif params[:eliminate][:before_photo] != nil
      #  # user uploaded a before photo
      #  @report.before_photo = params[:eliminate][:before_photo]
      #  @current_user.points += 100
      #  @current_user.total_points += 100
      #  @current_user.save
      #  if @report.save
      #    flash[:notice] = "You updated before photo"
      #    redirect_to(:back)
      #  else
      #    flash[:notice] = "An error has occured"
      #    redirect_to(:back)
      #  end
      #else
      #  redirect_to(:back)
      #end

    end #end of put statement

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
      @report = user.report_by_phone(params)
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
  def validate_report_submission params, report
    create_complete = true

    # If no report was filled out, then ask them to fill it out.
    if params[:report][:report] == ""
      flash[:alert] = flash[:alert].to_s + " Você tem que descrever o local e/ou o foco."
      create_complete = false
    end

    # If there was no before photograph, then ask them to upload it.
    if params[:report][:before_photo].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco encontrado."
      create_complete = false
    end

    # If elimination type is not selected
    if params[:report][:elimination_type].blank? && report.elimination_type.blank?
      # TODO Placeholder translated via Google Translate. "You must select a type of foco"
      flash[:alert] = flash[:alert].to_s + " Você deve selecionar um tipo de foco."
      create_complete = false
    end

    # If address is not completely filled out
    if (params[:street_name].blank? && report.location.street_name.blank?) ||
        (params[:street_number].blank? && report.location.street_number.blank?) ||
        (params[:street_type].blank? && report.location.street_type.blank?)
      # TODO Placeholder translated via Google Translate. "You must submit the entire address."
      flash[:alert] = flash[:alert].to_s + " Você deve enviar o endereço completo."
      create_complete = false
    end

    return create_complete

  end

end
