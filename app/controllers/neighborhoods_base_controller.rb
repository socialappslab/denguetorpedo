# -*- encoding : utf-8 -*-
class NeighborhoodsBaseController < ApplicationController
  before_filter :identify_neighborhood

  #----------------------------------------------------------------------------

  def identify_neighborhood
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])
  end

  #----------------------------------------------------------------------------

end
