class API::V0::ReportsController < API::V0::BaseController
  #----------------------------------------------------------------------------
  # GET /api/v0/reports

  def index
    render :json => {:reports => @user.reports.order("created_at DESC").as_json(:only => [:id, :report, :created_at], :include => {:location => {:only => [:address]}, :breeding_site => {:only => [:id, :description_in_es, :description_in_pt]}})}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/reports

  def create
    paperclip_image = nil
    if params[:report][:before_photo]
      base64_image = params[:report][:before_photo]
      params[:report].except!(:before_photo)
      filename             = @user.display_name.underscore + "_report.jpg"
      paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
    end

    @report                 = Report.new(params[:report])
    @report.reporter_id     = @user.id
    @report.neighborhood_id = @user.neighborhood_id
    @report.completed_at    = Time.now
    @report.before_photo    = paperclip_image

    if params[:report][:address].present?
      location = Location.find_or_create_by_address(params[:report][:address])
      @report.location_id = location.id
    end

    if @report.save
      render :json => @report.as_json(:only => [:id, :report, :created_at],
      :include => {
        :location => {:only => [:address]},
        :breeding_site => {
          :only => [:id, :description_in_es, :description_in_pt]
        }
      }), :status => 200 and return
    else
      raise API::V0::Error.new(@report.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------

end
