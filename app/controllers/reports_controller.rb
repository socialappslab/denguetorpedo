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

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports

  def index
    @current_report = params[:report]
    @current_user != nil ? @highlightReportItem = "nav_highlight" : @highlightReportItem = ""

    # new report form attributes
    # use existing params if error occured during create
    # report_params = session[:params][:report] if session[:params]
    #
    # # if report_params is present an error occurred during create, triggers showing new report tab in view
    # @create_error = report_params.present?
    #
    # @new_report = Report.new(report_params)
    # @new_report_location = Location.find_by_id(session[:location_id]) || Location.new

    @report          = Report.new

    reports_with_status_filtered = []
    locations                    = []
    open_locations               = []
    eliminated_locations         = []


    # TODO @awdorsett - the first Report all may not be needed, is it for SMS or elim type selection?
    # Set up a base SQL query that limits reports by neighborhood.
    # neighborhood_reports_sql_query = Report.joins(:location).where("locations.neighborhood_id = ?", @neighborhood.id)
    # @reports  = neighborhood_reports_sql_query.reject(&:completed_at).sort_by(&:created_at).reverse
    # @reports += neighborhood_reports_sql_query.select(&:completed_at).reject{|r| r.id == session[:saved_report]}.sort_by(&:completed_at).reverse


    # We only want to display the following reports:
    # 1. Logged-in user's reports, localized to the viewed neighborhood,
    # 2. All created reports (the misleading column completed_at is not nil)
    @reports = @current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a
    puts "@reports: #{@reports.inspect}"

    @reports += Report.select(&:completed_at).reject{|r| r.id == session[:saved_report]}.sort_by(&:completed_at).reverse
    puts "@reports: #{@reports.count}"

    @reports = @reports.find_all {|r| r.location && r.location.neighborhood_id == @neighborhood.id }

    puts "@reports: #{@reports.count}"

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


    @markers            = locations.compact.map { |location| location.info}
    @open_markers       = open_locations.compact.map { |location| location.info}
    @eliminated_markers = eliminated_locations.compact.map { |location| location.info}

    puts "@markers: #{@markers} | @open_markers: #{@open_markers} | @eliminated_markers: #{@eliminated_markers}"

    # TODO @awdorsett - Does this affect anything? possibly used when you chose elimination type afterwards
    #@reports = reports_with_status_filtered
    # TODO: These counts should be tied to the SQL query we're running to fetch the reports (see above)
    @counts            = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).group(:location_id).count
    @open_counts       = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 0).group(:location_id).count
    @eliminated_counts = Report.where('reporter_id = ? OR elimination_type IS NOT NULL', @current_user.id).where(status_cd: 1).group(:location_id).count


    @open_feed      = @reports
    @eliminate_feed = @reports

    puts "@@counts: #{@counts} | @open_counts: #{@open_counts} | @eliminated_counts: #{@eliminated_counts}"
  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/reports/1/new

  def new
    @report = Report.new
  end


  #-----------------------------------------------------------------------------
  # POST /reports

  def create
    # used to handle errors, if error occurs then set to false
    # create_complete = true

    # TODO @dman7: What is this???
    # flash[:street_type] = params[:street_type]
    # flash[:street_name] = params[:street_name]
    # flash[:street_number] = params[:street_number]
    # flash[:description] = params[:report][:report]
    # flash[:x] = params[:x]
    # flash[:y] = params[:y]

    # If location was previously created, use that
    # saved_location = Location.find_by_id(session[:location_id])
    # if saved_location
    #   location = saved_location
    # else
    #   # Find the location based on user's input (street type, name, number) and
    #   # ESRI's geolocation (latitude, longitude).
    #   # When the user inputs an address into the textfields, we trigger an ESRI
    #   # map search on the associated map that updates the x and y hidden fields
    #   # in the form. In the case that the map is unavailable (or JS is disabled),
    #   # an after_commit hook into the Location model will trigger a background
    #   # worker to fetch the map coordinates.
    #
    #   location = Location.find_or_create_by_street_type_and_street_name_and_street_number(
    #     params[:street_type].downcase.titleize,
    #     params[:street_name].downcase.titleize,
    #     params[:street_number].downcase.titleize
    #   )
    #
    #   location.latitude  = params[:x] if params[:x].present?
    #   location.longitude = params[:y] if params[:y].present?
    #   location.save
    # end

    # @report              = Report.new(params[:report])
    # @report.reporter_id  = @current_user.id
    # @report.location_id  = location.id
    # @report.status       = :reported # TODO @dman7: why is status (type int) but is assigned a symbol?
    # @report.report       = params[:report][:report] # TODO: Not really needed. ensure that it's already there.
    # @report.completed_at = Time.now
    # @report.before_photo = params[:report][:before_photo]

    # TODO: Fix this in the form instead
    params[:report].merge!(:reporter_id => @current_user.id, :completed_at => Time.now)
    @report = Report.new( params[:report] )
    if @report.save
      @report.update_attribute(:status, :reported)
      flash[:notice] = 'Foco marcado com sucesso!'
      redirect_to :action => 'index' and return
    else
      @reports = @current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a
      @reports += Report.select(&:completed_at).reject{|r| r.id == session[:saved_report]}.sort_by(&:completed_at).reverse
      @reports = @reports.find_all {|r| r.location && r.location.neighborhood_id == @neighborhood.id }

      # if report has been completed or has an error during update
      # TODO @awdorsett - more effecient way?
      if session[:saved_report]
        @reports = [Report.find_by_id(session[:saved_report])] + @reports
        session[:saved_report] = nil
      end


      render "index" and return
    end


    # Now let's save the report.
    # if create_complete && @report.save
    #   flash[:notice] = 'Foco marcado com sucesso!'
    #   redirect_to :action => 'index' and return
    # end

    # TODO @dman7: This is a hack to get to display the report errors.

    # Let's see if we can improve on this.
    #render_errors = @report.errors.full_messages.join("\n")
    #flash[:alert] = render_errors
    # used to return to create tab on error
    #puts "SESSION3"
    #puts params[:report]


  end

  #-----------------------------------------------------------------------------
  # GET /neighborhoods/1/edit

  def edit
    @report = current_user.created_reports.find( params[:id] )

    #flash[:street_type] = @report.location.street_type
    #flash[:street_name] = @report.location.street_name
    #flash[:street_number] = @report.location.street_number
    #flash[:x] = @report.location.latitude
    #flash[:y] = @report.location.longitude
    @new_report_location = Location.find_by_id(@report.location.id)
    # @elimination_types   = EliminationType.pluck(:name)
  end

  #-----------------------------------------------------------------------------
  # PUT /neighborhoods/1/reports
  #
  # NOTE: There are 2 gateways that a report can be updated:
  #   1. Via SMS
  #   2. User selecting an elimination method.
  #
  def update
    @report = Report.find_by_id(params[:id]) || Report.find_by_id( params[:report][:id] )

    submission_points = 50
    submit_complete   = true

    # TODO @dman7: Rage face!!! This needs to be done in the F*$ing form.
    if params[:report][:elimination_type].present?
      # params[:report][:elimination_type] = params[:elimination_type]
      params[:report][:completed_at]     = Time.now
    end

    params[:report].merge!(:status => :reported)



    if @report.sms_incomplete?
      # address = params[:street_type].downcase.titleize + " " + params[:street_name].downcase.titleize + " " + params[:street_number].downcase.titleize
      # location = Location.find_by_address(address)

      # if location.nil?
      #   location = Location.new(:street_type => params[:street_type].downcase.titleize, :street_name => params[:street_name].downcase.titleize, :street_number => params[:street_number].downcase.titleize, latitude: params[:x], longitude: params[:y])
      # else
      #   location.latitude = params[:x]
      #   location.longitude = params[:y]
      # end
      # location.save
      # @report.location = location


      # TODO @dman7: This really should be already in this format in the form...
      # params[:report][:location_attributes] = {
      #   :street_type => params[:street_type].downcase.titleize,
      #   :street_name => params[:street_name].downcase.titleize,
      #   :street_number => params[:street_number].downcase.titleize,
      #   :latitude  => params[:x],
      #   :longitude => params[:y]
      # }

      # We reward the user if the previous report did not have an elimination
      # type.
      should_reward_user = @report.elimination_type.nil?
      if @report.update_attributes( params[:report] )

        if should_reward_user
          @current_user.update_attribute(:points, @current_user.points + submission_points)
          @current_user.update_attribute(:total_points, @current_user.total_points + submission_points)
        end

        @report.update_attributes(completed_at: Time.now)
        flash[:notice] = "Foco completado com sucesso!"
        redirect_to neighborhood_reports_path(@neighborhood) and return
      else
        render "edit" and return
      end
    end




    # Check to see if user has selected a method of elimination
    if params[:report][:elimination_method].blank?
      flash[:alert] = "Você tem que escolher um método de eliminação"
      redirect_to :back and return
    end

    if params[:report][:after_photo].blank?
      flash[:alert] = flash[:alert].to_s + " Você tem que carregar uma foto do foco eliminado." #You have to upload a photo of focus eliminated
      redirect_to :back and return
    end


    # Check if a location lon/lat exists
    # TODO @awdorsett check if error message is correct in portuguese
    # if @report.location.latitude.blank? || @report.location.longitude.blank?
    #   if params[:latitude].present? || params[:longitude].present?
    #     # TODO @awdorsett find out why location doesn't save when report.save is called
    #     @report.location.latitude = params[:latitude]
    #     @report.location.longitude = params[:longitude]
    #     @report.location.save
    #   #else
    #   #  flash[:notice] = flash[:notice].to_s + ' Você tem que selecionar um local no mapa' #You have to select a location on the map
    #   #  submit_complete = false
    #   end
    # end
    #

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

    # @report.save

    # if every part of the report submission is complete, submit_complete = true

    # TODO: Theoretically, if we're at this point, we're safe.
    session[:saved_report]= @report.id

    if @report.update_attributes( params[:report] )
      flash[:notice] = "Você eliminou o foco!"
      @report.touch(:eliminated_at)
      @report.update_attribute(:status_cd, 1)
      @report.update_attribute(:eliminator_id, @current_user.id)
      award_points @report, @current_user

      redirect_to :back and return
    else
      @reports = @current_user.reports.where(:completed_at => nil).order("created_at DESC").to_a
      @reports += Report.select(&:completed_at).reject{|r| r.id == session[:saved_report]}.sort_by(&:completed_at).reverse
      @reports = @reports.find_all {|r| r.location && r.location.neighborhood_id == @neighborhood.id }

      # if report has been completed or has an error during update
      # TODO @awdorsett - more effecient way?
      if session[:saved_report]
        @reports = [Report.find_by_id(session[:saved_report])] + @reports
        session[:saved_report] = nil
      end


      render "index" and return
    end



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
  # POST /gateway
  #
  # NOTE: This is where the SMS come in
  #------------------------------------

  def gateway
    @user = User.find_by_phone_number(params[:from]) if params[:from].present?

    respond_to do |format|
      if @user
        if @user.residents?
          @report = @user.report_by_phone(params)

          # TODO: SInce this is a new report, it won't have certain things, such
          # as before photo.
          if @report.save(:validate => false)
            Notification.create(board: "5521981865344", phone: params[:from], text: "Parabéns! O seu relato foi recebido e adicionado ao Dengue Torpedo.")
            format.json { render json: { message: "success", report: @report}}
          else
            Notification.create(board: "5521981865344", phone: params[:from], text: "Nós não pudemos adicionar o seu relato porque houve um erro no nosso sistema.")
            format.json { render json: { message: @report.errors.full_messages}, status: 401}
          end
        else
          Notification.create(board: "5521981865344", phone: params[:from], text: "O seu perfil não está habilitado para o envio do Dengue Torpedo.")
          format.json { render json: { message: "Sponsors or verifiers"}, status: 401}
        end
      else
        Notification.create(board: "5521981865344", phone: params[:from], text: "Você ainda não tem uma conta. Registre-se no site do Dengue Torpedo.")
        format.json { render json: { message: "There is no registered user with the given phone number."}, status: 404}
      end
    end
  end

  #----------------------------------------------------------------------------

  def notifications
    @notifications = Notification.unread
    @notifications.each { |notification| notification.read = true; notification.save }
    respond_to do |format|
      format.json { render json: @notifications }
    end
  end

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

end
