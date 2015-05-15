# -*- encoding : utf-8 -*-
class Dashboard::BaseController < ApplicationController
  layout "layouts/dashboard"

  #----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :authorize_user
  before_filter :set_navigational_components

  #----------------------------------------------------------------------------

  protected

  def identify_neighborhood
    # Identify the neighborhood that the user is interested in.
    neighborhood_id = cookies[:neighborhood_id] || @current_user.neighborhood_id
    @neighborhood   = Neighborhood.find_by_id(neighborhood_id)
  end

  #----------------------------------------------------------------------------

  private

  def authorize_user
    # TODO: Need to add pundit logic here.
    return true
  end

  def set_navigational_components
    @navigation            ||= {}
    @navigation["parent"]  ||= {}
    @navigation["child"]   ||= {}
    @navigation["current"] ||= {}
  end

  #----------------------------------------------------------------------------

 end
