# -*- encoding : utf-8 -*-
class CitiesController < ApplicationController
  include GreenLocationRankings

  #----------------------------------------------------------------------------
  # GET /cities

  def index
    @neighborhoods = Neighborhood.all
  end

  #----------------------------------------------------------------------------
  # GET /cities/:id

  def show
    @city          = City.find( params[:id] )
    @cities        = City.order("name ASC")
    @neighborhoods = Neighborhood.where(:city_id => @city.id)

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    end

    # Let's try to retrieve
    @green_location_rankings = GreenLocationRankings.top_ten_for_city(@city)
    @neighborhood_rankings = @neighborhoods.map do |n|
      {:id => n.id, :score => GreenLocationSeries.get_latest_count_for_neighborhood(n).to_i}
    end

    @breadcrumbs << {:name => @city.name, :path => city_path(@city)}
  end


  #----------------------------------------------------------------------------

  private
end
