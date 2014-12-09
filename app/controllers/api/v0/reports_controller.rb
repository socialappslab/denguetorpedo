class API::V0::ReportsController < API::V0::BaseController
  #----------------------------------------------------------------------------
  # GET /api/v0/reports

  def index
    render :json => {:reports => @user.reports.order("created_at DESC").as_json(:only => [:id, :report, :created_at], :include => {:location => {:only => [:address]}, :breeding_site => {:only => [:id, :description_in_es, :description_in_pt]}})}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
end
