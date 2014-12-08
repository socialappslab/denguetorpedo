class API::V0::ReportsController < API::V0::BaseController
  #----------------------------------------------------------------------------
  # GET /api/v0/reports

  def index
    render :json => @user.reports, :status => 200 and return
  end

  #----------------------------------------------------------------------------
end
