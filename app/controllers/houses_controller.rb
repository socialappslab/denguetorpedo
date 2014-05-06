# encoding: utf-8
class HousesController < NeighborhoodsBaseController
  before_filter :require_login

  def show
    @house = House.includes(:members, :posts).find(params[:id])

    head :not_found and return if @house.nil?
    head :not_found and return if @house.user && @house.user.role == User::Types::SPONSOR

    @post = Post.new
    excluded_roles = ["lojista", "verificador"]
    @neighbors = House.joins(:user).where(:neighborhood_id => @neighborhood.id)
    @neighbors = @neighbors.where('users.role NOT IN (?) AND houses.id != ?', excluded_roles, @house.id).uniq.shuffle[0..6]

    # TODO: Make this specific to each neighborhood.
    @reports                  = @house.reports.find_all { |r| r.neighborhood_id == @neighborhood.id }
    @open_house_reports       = @reports.find_all { |r| r.status == Report::STATUS[:reported] }
    @eliminated_house_reports = @reports.find_all { |r| r.status == Report::STATUS[:eliminated] }

    @open_markers       = @open_house_reports.map { |report| report.location && report.location.as_json(:only => [:latitude, :longitude])}
    @eliminated_markers = @eliminated_house_reports.map { |report| report.location && report.location.as_json(:only => [:latitude, :longitude])}

    @open_markers.compact!
    @eliminated_markers.compact!
  end

  def new
    @house = House.new
    @house_name_confirmation = false
  end

  def create
    @house = House.new(params[:house])

    house = House.find_by_name(params[:house][:name])
    if params[:house][:name_confirmation].blank? && house.present? && @current_user.house_id != house.id
      @current_user.house = house

      @house_name_confirmation = true
      flash[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."

      render "new" and return
    end


    if @house.save
      flash[:notice] = "Casa atualizado com sucesso!"
      redirect_to neighborhood_house_path(@neighborhood, @house) and return
    else
      render "new" and return
    end


  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def redirect_if_missing_house
    redirect_to new_neighborhood_house_path(@neighborhood) if @current_user.house.blank?
  end

  #----------------------------------------------------------------------------

end
