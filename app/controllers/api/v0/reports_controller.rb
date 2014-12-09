class API::V0::ReportsController < API::V0::BaseController
  #----------------------------------------------------------------------------
  # GET /api/v0/reports

  def index
    render :json => {:reports => @user.reports.order("created_at DESC").as_json(:only => [:id, :report, :created_at], :include => {:location => {:only => [:address]}, :breeding_site => {:only => [:id, :description_in_es, :description_in_pt]}})}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/reports

  def create
    puts "params: #{params}"
    @report                 = Report.new(params[:report])
    @report.reporter_id     = @user.id
    @report.neighborhood_id = @user.neighborhood_id
    @report.completed_at    = Time.now

    if params[:report][:address].present?
      location = Location.find_or_create_by_address(params[:report][:address])
      @report.location_id = location.id
    end

    puts "@report: #{@report.inspect} | @report.save: #{@report.save!}"

    if @report.save
      render :json => @report, :status => 200 and return
    else
      raise API::V0::Error.new(@report.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------

end
