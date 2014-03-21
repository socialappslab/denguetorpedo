class HomeController < ApplicationController
  def index
    @user = @current_user || User.new

    @all_neighborhoods     = Neighborhood.order(:id).limit(3)
    @selected_neighborhood = @all_neighborhoods.first
    @participants          = @selected_neighborhood.members.where('role != ?', "lojista")

    @houses       = @participants.map { |participant| participant.house }.uniq.shuffle
    @prizes       = Prize.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new)
  end
end
