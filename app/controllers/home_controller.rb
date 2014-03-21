class HomeController < ApplicationController
  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = @current_user || User.new

    @all_neighborhoods     = Neighborhood.order(:id).limit(3)
    @selected_neighborhood = @all_neighborhoods.first
    @participants          = @selected_neighborhood.members.where('role != ?', "lojista")

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
