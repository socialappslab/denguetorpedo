# -*- encoding : utf-8 -*-

class Coordinator::HomeController < Coordinator::BaseController
  #----------------------------------------------------------------------------
  # GET /coordinator/

  def index
    # TODO: Change to appropriate policy.
    authorize! :edit, User
    authorize! :edit, Team
  end

  #----------------------------------------------------------------------------
end
