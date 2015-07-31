# -*- encoding : utf-8 -*-

class Coordinator::NoticesController < Coordinator::BaseController

  #----------------------------------------------------------------------------
  # GET /coordinator/notices/new

  def new
    @notice = Notice.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @notice }
    end
  end


  #----------------------------------------------------------------------------

end
