# -*- encoding : utf-8 -*-
class API::V0::InspectionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # PUT /api/v0/inspections/:id

  def update
    @inspection = Inspection.find_by_id(params[:id])
    if @inspection.update_attributes(params[:inspection])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@inspection.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------
end
