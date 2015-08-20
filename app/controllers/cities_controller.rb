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
    @neighborhoods = Neighborhood.where(:city_id => @city.id)

    # Calculate ranking for each community.
    rankings  = @neighborhoods.map {|n| [n, n.total_points]}
    @rankings = rankings.sort {|a, b| a[1] <=> b[1]}.reverse

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    end

    @breadcrumbs << {:name => I18n.t("activerecord.models.neighborhood", :count => 2), :path => city_path(@city)}
  end

  #----------------------------------------------------------------------------
  # GET /cities/:id

  def new_show
    @city          = City.find( params[:id] )
    @neighborhoods = Neighborhood.where(:city_id => @city.id)

    # Calculate ranking for each community.
    rankings  = @neighborhoods.map {|n| [n, n.total_points]}
    @rankings = rankings.sort {|a, b| a[1] <=> b[1]}.reverse

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    end

    @breadcrumbs << {:name => @city.name, :path => city_path(@city)}

    @cities = City.order("name ASC")
  end


  #----------------------------------------------------------------------------

  private
end
