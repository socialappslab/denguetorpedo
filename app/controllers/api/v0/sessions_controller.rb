# -*- encoding : utf-8 -*-
class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :authenticate_user_via_jwt, :only => [:current]
  before_filter :current_user_via_jwt,      :only => [:current]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?

    if user.present? && user.authenticate(params[:password])
      render :json => {
        :token => user.jwt_token,
        :user => {
          :id => user.id,
          :display_name  => user.display_name,
          :profile_photo => user.profile_photo.url(:thumbnail),
          :neighborhood  => {
            :id   => user.neighborhood_id,
            :name => user.neighborhood.geographical_display_name
          },
          :breeding_sites => BreedingSite.all.as_json(:only => [:id], :methods => [:description]),
          :neighborhoods => Neighborhood.all.as_json(:only => [:id, :name]),
          :total_points  => user.total_total_points,
          :green_locations => GreenLocationRankings.score_for_user(user).to_i
        }
      }, :status => 200
    else
      raise API::V0::Error.new("Invalid email or password. Please try again.", 401) and return
    end

  end

  #----------------------------------------------------------------------------
  # GET /api/v0/sessions/current

  def current
  end

  #----------------------------------------------------------------------------
end
