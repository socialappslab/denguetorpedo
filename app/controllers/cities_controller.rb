# -*- encoding : utf-8 -*-
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
    @cities        = City.order("name ASC")
    @neighborhoods = Neighborhood.where(:city_id => @city.id)

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    end

    @breadcrumbs << {:name => @city.name, :path => city_path(@city)}
  end


  #----------------------------------------------------------------------------

  private
end
