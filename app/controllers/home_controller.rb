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
    @participants          = @selected_neighborhood.members.where('role != ?', "lojista")

    @notices      = @selected_neighborhood.notices.limit(5).order(:date)
    @houses       = @participants.map { |participant| participant.house }.uniq.shuffle
    @prizes       = Prize.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new)
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
