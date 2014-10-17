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

    # Calculate ranking for each community.
    rankings  = @neighborhoods.map {|n| [n, n.total_points]}
    @rankings = rankings.sort {|a, b| a[1] <=> b[1]}.reverse
  end


  #----------------------------------------------------------------------------
end
