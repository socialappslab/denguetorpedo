# -*- encoding : utf-8 -*-
class API::V0::UsersController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/users/:id/scores

  def scores
    @user = User.find_by_id(params[:user_id])
    @report_count = @user.reports.completed.count
    @green_location_ranking = GreenLocationRankings.score_for_user(@user).to_i

    render :json => {:points => @user.total_total_points, :report_count => @report_count, :green_location_ranking => @green_location_ranking}, :status => :ok and return
  end

  #----------------------------------------------------------------------------
end
