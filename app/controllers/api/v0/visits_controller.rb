# -*- encoding : utf-8 -*-
class API::V0::VisitsController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token
  before_action :current_user

  #----------------------------------------------------------------------------
  # GET api/v0/visits/:id

  def update
    @visit = Visit.find_by_id(params[:id])
    if @visit.update_attributes(params[:visit])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@visit.errors.full_messages[0], 403)
    end
  end
end
