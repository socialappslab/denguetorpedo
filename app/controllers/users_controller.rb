#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController

  before_filter :require_login, :only => [:edit, :update, :index, :show]

  before_filter :ensure_mare_neighborhood, :only => [:update]

  def index

    if params[:q].nil? or params[:q] == ""
      @users = User.residents.order(:first_name)
      @sponsors = User.where(:role => "lojista").order(:first_name)
      @verifiers = User.where(:role => "verificador").order(:first_name)
      @visitors = User.where(:role => "visitante").order(:first_name)
    else
      @users = User.where(:role => "morador").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @sponsors = User.where(:role => "lojista").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @sponsors = House.where('lower(name) LIKE lower(?)', params[:q] + "%").map { |house| house.user }.compact
      @verifiers = User.where(:role => "verificador").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @visitors = User.where(:role => "visitante").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
    end
    @prizes = Prize.where(:is_badge => false)
    authorize! :assign_roles, User

    respond_to do |format|
      format.html
      format.json { render json: { users: @users}}
    end
  end

  #----------------------------------------------------------------------------

  def show
    @post = Post.new

    @user         = User.find_by_id(params[:id])
    @neighborhood = @user.neighborhood
    @house        = @user.house
    @prizes       = @user.prizes
    @badges       = @user.badges

    head :not_found and return if @user != @current_user and @user.role == "lojista"
    head :not_found and return if @user.nil?

    @user_posts = @user.posts
    @elimination_method_select = EliminationMethods.field_select




    @prize_ids = @prizes.collect{|prize| prize.id}


    @isPrivatePage = (@user == @current_user)
    @highlightProfileItem = @isPrivatePage ? "nav_highlight" : ""
    @coupons = @user.prize_codes
    if params[:filter] == 'reports'
      @feed_active_reports = 'active'
      @combined_sorted = @user.reports.where('elimination_type IS NOT NULL')
    elsif params[:filter] == 'posts'
      @combined_sorted = @user.posts
      @feed_active_posts = 'active'
    else
      @feed_active_all = 'active'
      @combined_sorted = (@user.reports.where('elimination_type IS NOT NULL') + @user.posts).sort{|a,b| b.created_at <=> a.created_at }
    end

    @stats_hash = {}
    @stats_hash['opened'] = @user.created_reports.count
    @stats_hash['eliminated'] = @user.eliminated_reports.count

    @elimination_method_select = EliminationMethods.field_select
    @elimination_types = EliminationType.pluck(:name)
    reports_with_status_filtered = []
    locations = []

    @prantinho = EliminationMethods.prantinho
    @pneu = EliminationMethods.pneu
    @lixo = EliminationMethods.lixo
    @pequenos = EliminationMethods.pequenos
    @caixa = EliminationMethods.caixa
    @grandes = EliminationMethods.grandes
    @calha = EliminationMethods.calha
    @registros = EliminationMethods.registros
    @laje = EliminationMethods.laje
    @piscinas = EliminationMethods.piscinas
    @pocas = EliminationMethods.pocas
    @ralos = EliminationMethods.ralos
    @plantas = EliminationMethods.plantas
    respond_to do |format|
      format.html
      format.json { render json: {user: @user, house: @house, prizes: @prizes, badges: @badges}}
    end
  end

  #----------------------------------------------------------------------------

  def new
    @user = User.new
  end

  def special_new
    authorize! :edit, User.new
    @user ||= User.new
    @user.house ||= House.new
    @user.house.location ||= Location.new

    if @user.house.location.latitude.nil?
      @user.house.location.latitude = 0
      @user.house.location.longitude = 0
    end
  end

  def create
    #remove whitespace from user signup
    params[:user].each{|key,val| params[:user][key] = params[:user][key].strip}

    @user = User.new(params[:user])
    if @user.save
      cookies[:auth_token] = @user.auth_token
      redirect_to edit_user_path(@user)
    else
      render new_user_path(@user)
    end
  end

  def edit

    @user = User.find(params[:id])
    @user.house ||= House.new
    @user.house.location ||= Location.new
    @user.house.location.latitude ||= 0
    @user.house.location.longitude ||= 0
    @highlightAccountItem = "nav_highlight"
    @verifiers = User.where(:role => "verificador").map { |verifier| {:value => verifier.id, :label => verifier.full_name}}.to_json
    @residents = User.residents.map { |resident| {:value => resident.id, :label => resident.full_name}}.to_json
    if @user != @current_user
      authorize! :edit, @user
    end
    @confirm = 0
    # flash[:notice] = nil
  end


  #----------------------------------------------------------------------------
  # Started PUT "/users/3?html%5Bautocomplete%5D=off&html%5Bmultipart%5D=true" for 127.0.0.1 at 2014-03-27 20:41:53 -0700
  # Parameters: {
  #   "user" => {
  #     "first_name"=>"Mister",
  #     "last_name"=>"Tester",
  #     "nickname"=>"",
  #     "gender"=>"true",
  #     "email"=>"a@denguetorpedo.com",
  #     "phone_number"=>"000000000000",
  #     "carrier"=>"xxx",
  #     "prepaid"=>"true",
  #     "house_attributes"=>{"name"=>"Test"},
  #     "neighborhood_id"=>"3",
  #     "location"=>{"street_type"=>"", "street_name"=>"", "street_number"=>""}
  #   },
  #   "display"=>"firstmiddlelast", "id"=>"3"
  # }


  def update
    #--------------------------------------------------------------------------
    # Handle carrier and prepaid errors.
    if params[:user][:carrier].blank?
      flash[:alert] = "Informe a sua operadora."
      redirect_to :back and return
    elsif params[:user][:prepaid].blank?
      flash[:alert] = "Marque pré ou pós-pago."
      redirect_to :back and return
    end

    # NOTE: This is essentially the old code boiled down. Before
    # saving it along with the user attributes, we do a quick query
    # to identify the house by its name. If it's present, we don't ask the user
    # to confirm, but instead we update the ID and the name, and save.
    house = House.find_by_name(params[:user][:house_attributes][:name])
    if house.present?
      params[:user][:house_attributes].merge!(:id => house.id, :name => house.name)
    end

    # Now, let's find the neighborhood that the user has specified. If it actually
    # exists, then we'll update the house_attributes and pass it on to Rails's
    # saver.
    neighborhood = Neighborhood.find(params[:user][:neighborhood_id])
    params[:user][:house_attributes].merge!(:neighborhood_id => neighborhood.id)

    #--------------------------------------------------------------------------
    # Update the user and the house.

    @user = User.find(params[:id])
    user_params = params[:user].slice(:house_attributes, :profile_photo, :gender, :email, :display, :first_name, :last_name, :nickname, :phone_number, :carrier, :prepaid, :neighborhood_id)
    if @user.update_attributes(user_params)
      @user.update_attribute(:is_fully_registered, true)

      # Identify the recruiter for this user.
      recruiter = User.find_by_id(params[:recruitment_id])
      if recruiter
        @user.recruiter = recruiter
        recruiter.points       += 50
        recruiter.total_points += 50
        recruiter.save
      end
    else
      render "edit" and return
    end

    #--------------------------------------------------------------------------
    # TODO: I'm going to deprecate this alert behavior where we ask the user to confirm
    # their house. I'm doing this for simplicity of the codebase. When we're done
    # cleaning the code, we can come back to it and make the functionality more
    # fancy...
    # if a house exists with the same house name or house address, inform the user for confirmation
    # if !house_name.blank? && House.find_by_name(house_name) && params[:user][:confirm].to_i == 0 && (!@user.house || (house_name != @user.house.name))
    #   @user.house ||= House.new
    #   @user.house.location ||= Location.new
    #   @user.house.location.street_type = params[:user][:location][:street_type]
    #   @user.house.location.street_name = params[:user][:location][:street_name]
    #   @user.house.location.street_number = params[:user][:location][:street_number]
    #   @user.house.location.neighborhood = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])
    #   @user.house.location.latitude ||= 0
    #   @user.house.location.longitude ||= 0
    #   @user.house.name = house_name
    #   @confirm = 1
    #   flash.now[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."
    #
    #   render "edit"
    # else

    #--------------------------------------------------------------------------
    # Finally, let's update the location of the house, if specified.
    location = @user.house.location
    location = Location.new if location.nil?

    location.street_type      = params[:user][:location][:street_type]
    location.street_name      = params[:user][:location][:street_name]
    location.street_number    = params[:user] [:location][:street_number]
    location.neighborhood_id  = @user.neighborhood.id
    location.latitude         = params[:x]
    location.longitude        = params[:y]

    unless location.save
      flash[:notice] = "Insira um endereço válido."
      render "edit" and return
    end

    redirect_to edit_user_path(@user), :flash => { :notice => 'Perfil atualizado com sucesso!' }
  end


  #----------------------------------------------------------------------------

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    if @user.house.members.count == 0
      @user.house.destroy
    end
    respond_to do |format|
      format.html { redirect_to users_url, :notice => "Usuário deletado com sucesso." }
      format.json { head :no_content }
    end
  end

  #Get /user/:id/buy_prize/prize_id
  def buy_prize
    @user = User.find(params[:id])
    bought = @user.buy_prize(params[:prize_id])
    if bought
      @prize_code = PrizeCode.where(:prize_id => params[:prize_id], :user_id => params[:id]).limit(1)[0]
    end
    render :partial => "prizes/prizeconfirmation", :locals => {:bought => bought}
  end

  def special_create

    @user = User.new(params[:user])
    authorize! :edit, @user
    if params[:user][:house_attributes]
      @neighborhood = Neighborhood.find(params[:user][:location][:neighborhood_id])

      house_name = params[:user][:house_attributes][:name]
      street_type = params[:user][:location][:street_type]
      street_name = params[:user][:location][:street_name]
      street_number = params[:user] [:location][:street_number]
      house_address = street_type + " " + street_name + " " + street_number
      house_neighborhood = @neighborhood.name
      house_profile_photo = params[:user][:house_attributes][:profile_photo]
      house_phone_number = params[:user][:house_attributes][:phone_number]
      @user.house = House.find_or_create(house_name, house_address, house_neighborhood, house_profile_photo)

      if @user.house == nil
        if params[:user][:role] == "lojista"
          flash[:alert] = "There was an error creating a sponsor."
        else
          flash[:alert] = "There was an error creating a verifier."
        end
        render special_new_users_path(@user)
        return
      end
      @user.house.house_type = params[:user][:role]
      location = @user.house.location
      @user.house.phone_number = house_phone_number
      @user.house.save
      location.street_type = params[:user][:location][:street_type]
      location.street_name = params[:user][:location][:street_name]
      location.street_number = params[:user] [:location][:street_number]

      location.latitude     = params[:x]
      location.longitude    = params[:y]
      location.neighborhood = @neighborhood

      unless location.save
        redirect_to :back, :flash => { :notice => "There was an error with your address."}
        return
      end
    end

    if @user.save
      redirect_to "/users/special_new", :flash => { :notice => "Novo usuário criado com sucesso!"}
    else
      @user.house.destroy if @user.house
      # redirect_to "/users/special_new", :flash => { :notice => "Novo usuário criado com sucesso!"}
      render special_new_users_path(@user), flash: { alert: @user.errors.full_messages.join(', ')}
    end
  end

  def block
    @user = User.find(params[:id])
    @user.is_blocked = !@user.is_blocked
    if @user.save
      if @user.is_blocked
        redirect_to users_path, notice: "Usuário bloqueado com sucesso."
      else
        redirect_to users_path, notice: "Usuário desbloqueado com sucesso."
      end
    else
      redirect_to users_path, notice: "There was an error blocking the user"
    end
  end

  def phones
    @users = User.residents.order(:first_name)
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  # TODO: We're disabling choosing other neighborhoods until we introduce
  # another neighborhood. See seeds.rb for more.
  def ensure_mare_neighborhood
    neighborhood = Neighborhood.find(params[:user][:neighborhood_id])
    raise "This neighborhood is not allowed" unless neighborhood.name == "Maré"
  end

  #----------------------------------------------------------------------------

end
