class CitiesController < ApplicationController
  #----------------------------------------------------------------------------
  # GET /cities

  def index
    @neighborhoods = Neighborhood.all
  end

  #----------------------------------------------------------------------------
  # GET /cities/:id

  def show
    @city          = City.find( params[:id] )
    @neighborhoods = Neighborhood.where(:city_id => @city.id)
  end


  #----------------------------------------------------------------------------
end
