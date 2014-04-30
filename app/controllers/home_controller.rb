class HomeController < ApplicationController
  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = @current_user || User.new

    # NOTE: This is a hack that allows us to reuse this action with both
    # logged-in and visitors. Basically, a logged-in user cares only about
    # his/her own neighborhood.
    if @current_user.present?
      if @current_user.neighborhood.present?
        @all_neighborhoods = [ @current_user.neighborhood ]
      else
        @all_neighborhoods = [ Neighborhood.first ]
      end
    else
      @all_neighborhoods     = Neighborhood.order(:id).limit(3)
    end

    @selected_neighborhood = @all_neighborhoods.first

    @notices      = @selected_neighborhood.notices.limit(5).order(:date)
    @houses       = @selected_neighborhood.houses.limit(5) # @participants.map { |participant| participant.house }.shuffle

    # We want to limit number of houses displayed on the splash page for non-logged
    # in users.
    @houses = @houses[0..5] if @current_user.nil?

    @prizes  = Prize.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new).limit(3)
  end

  #----------------------------------------------------------------------------
  # GET /howto

  def howto
    @sections = DocumentationSection.order("order_id ASC")
  end

  #----------------------------------------------------------------------------
  # POST /neighborhood-search
  #
  # Parameters:
  # { "neighborhood"=>{"name"=>"Vila Autódromo"} }

  def neighborhood_search
    neighborhood = Neighborhood.find_by_name(params[:neighborhood][:name])
    redirect_to neighborhood_path(neighborhood)
  end

  #----------------------------------------------------------------------------
end
