#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController
  before_filter :require_login, :only => [:edit, :update, :index, :show]

  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------

  def show
    @post = Post.new

    @user = User.find_by_id(params[:id]) || User.find_by_auth_token(params[:auth_token])

    head :not_found and return if @user != @current_user and @user.role == "lojista"
    head :not_found and return if @user.nil?

    @user_posts = @user.posts
    @elimination_method_select = EliminationMethods.field_select

    @house = @user.house
    @neighborhood = @user.neighborhood
    @prizes = @user.prizes
    @prize_ids = @prizes.collect{|prize| prize.id}
    @badges = @user.badges

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

  #-----------------------------------------------------------------------------

  def new
    @user = User.new
  end

  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------
  # POST /users


  # Parameters passed:
  #   Parameters:
  #   "user"=>{
  #     "email"=>"12312", "first_name"=>"123423",
  #     "last_name"=>"242334", "password"=>"[FILTERED]",
  #     "password_confirmation"=>"[FILTERED]"
  #   }
  def create
    user_params = params[:user]
    if user_params.nil?
      # TODO TODO @dman7: Need to internationalize the messages...
      # SEE: https://github.com/socialappslab/denguetorpedo/issues/14
      @user         = User.new
      flash[:alert] = "Something went wrong. Please try again."
      render "new" and return
    end

    # At this point, we know that the user submitted non-trivial
    # params. Let's clean them up and try to save the user.
    user_params.each{|key,val| user_params[key] = val.strip}
    @user = User.new(user_params)
    if @user.save
      login_user(@user)
      redirect_to edit_user_path(@user) and return
    else
      render "new" and return
    end
  end

  #-----------------------------------------------------------------------------

  def edit
    @user = User.find(params[:id])

    @user.house                    ||= House.new
    @user.house.location           ||= Location.new
    @user.house.location.latitude  ||= 0
    @user.house.location.longitude ||= 0
    @highlightAccountItem = "nav_highlight"
    @verifiers = User.where(:role => "verificador").map { |verifier| {:value => verifier.id, :label => verifier.full_name}}.to_json
    @residents = User.residents.map { |resident| {:value => resident.id, :label => resident.full_name}}.to_json
    if @user != @current_user
      authorize! :edit, @user
    end
    @confirm = 0
  end

  #-----------------------------------------------------------------------------

  # def update

  #   @user = User.find(params[:id])
  #   @user.update_attributes(params[:user])
  #   if @user.house == nil
  #     if house = House.find_by_name(params[:user][:house_attributes][:name])
  #       if params[:confirm] == "1"
  #         @user.house = house
  #       else
  #         flash[:notice] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."
  #         @confirm = 1
  #         render "edit"
  #       end


  #     else

  #       @user.house = House.create!(params[:user][:house_attributes])
  #     end
  #   else
  #     @user.house.update_attributes(params[:user][:house_attributes])
  #     @user.house.save
  #   end
  #   if @user.save
  #     flash[:notice] = 'Perfil atualizado com sucesso!'
  #     redirect_to edit_user_path(@user)
  #   else
  #     flash[:alert] = @user.errors.full_messages.join(" ")
  #     @user.house ||= House.new
  #     @user.house.location ||= Location.new
  #     @user.house.location.latitude ||= 0
  #     @user.house.location.longitude ||= 0
  #     render "edit"
  #   end


  # end

  #-----------------------------------------------------------------------------
  # PUT /users/1

  # Parameters:
  # :user => {
  #   :first_name => "Test",
  #   :last_name  => "Tester",
  #   :email => "test@denguetorpedo.com",
  #   :phone_number => "000000000000",
  #   :carrier => "xxx",
  #   :prepaid => "true",
  #   :house_attributes => {"name"=>"4314234314234314", "id"=>"2"}
  #   :location => {"neighborhood"=>"Maré", "street_type"=>"", "street_name"=>"", "street_number"=>""}
  #   :
  # }
  def update
    @user = User.find(params[:id])

    user_params = params[:user]

    # Ensure that phone number, carrier and prepaid options
    # are selected.
    if user_params[:phone_number].length < 12
      flash[:alert] = "Número de celular invalido.  O formato correto é 0219xxxxxxxx."
      redirect_to edit_user_path(@user) and return
    end

    if user_params[:carrier].empty?
      flash[:alert] = "Informe a sua operadora."
      redirect_to edit_user_path(@user) and return
    end

    if user_params[:prepaid].empty?
      flash[:alert] = "Marque pré ou pós-pago."
      redirect_to edit_user_path(@user) and return
    end

    if user_params[:house_attributes].blank? || user_params[:house_attributes][:name].blank?
      flash[:alert] = "Preencha o nome da casa."
      redirect_to edit_user_path(@user) and return
    end

    unless @user.update_attributes(user_params)
      render edit_user_path(@user) and return
    end

    # At this point, the user's information has been saved and we have
    # a house name. Let's go ahead and try to match the name of the house
    # with something in our database. If we haven't confirmed his/her
    # house yet, then let's do that now.
    house_name = user_params[:house_attributes][:name]
    house      = House.find_by_name(house_name)

    # If a house exists with the same house name or house address, inform the
    # user for confirmation ONLY IF the user hasn't been asked before.
    if user_params[:confirm].to_i == 0
      if house.present? && (@user.house.blank? || @user.house.name != house_name)
        @user.house          ||= House.new
        @user.house.location ||= Location.new
        # TODO: If the house already exists, then why not just copy the location????
        @user.house.location.street_type   = user_params[:location][:street_type]
        @user.house.location.street_name   = user_params[:location][:street_name]
        @user.house.location.street_number = user_params[:location][:street_number]
        @user.house.location.neighborhood  = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])
        @user.house.location.latitude    ||= 0
        @user.house.location.longitude   ||= 0
        @user.house.name                   = house_name

        # By setting this to 1, we won't ask the user again to confirm.
        @confirm = 1
        flash.now[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."
        render "edit" and return
      end
    end




    # TODO TODO: need to deprecate these variables...
    house_address = user_params[:location][:address] || ''
    house_neighborhood = user_params[:location][:neighborhood] || ''
    house_profile_photo = user_params[:house_attributes][:profile_photo] || ''

    @user.display = display
    @user.first_name = user_first_name
    #@user.middle_name = user_middle_name
    @user.last_name = user_last_name
    @user.nickname = user_nickname

    user_profile_photo = params[:user][:profile_photo]
    display = params[:display]
    user_first_name = params[:user][:first_name]
    user_last_name = params[:user][:last_name]
    #user_middle_name = params[:user][:middle_name]
    user_nickname = params[:user][:nickname]



    if @user.role != "visitante"
      house_address = params[:user][:location][:street_type].titleize + " " + params[:user][:location][:street_name].titleize + " " + params[:user][:location][:street_number].titleize


      if @user.house
        @user.house.name = house_name
        if house_profile_photo
          @user.house.profile_photo = house_profile_photo
        end
        location = @user.house.location
        location.street_type = params[:user][:location][:street_type]
        location.street_name = params[:user][:location][:street_name]
        location.street_number = params[:user] [:location][:street_number]
        location.neighborhood = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])
        if params[:x] and params[:y]
          location.latitude = params[:x]
          location.longitude = params[:y]
        end
        if !location.save
          flash[:notice] = "Insira um endereço válido."
          render "edit"
          return
        end
      else
        @user.house = House.find_or_create(house_name, house_address, house_neighborhood, house_profile_photo)

        if !@user.house.valid?
          flash[:alert] = "Insira um nome da casa válido."
          render "edit"
          return
        else
          location = @user.house.location
          location.street_type = params[:user][:location][:street_type]
          location.street_name = params[:user][:location][:street_name]
          location.street_number = params[:user] [:location][:street_number]
          location.neighborhood = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])
          location.latitude = params[:x]
          location.longitude = params[:y]
          location.save
        end
      end
    end



    if @user.house and !@user.house.save
      flash[:notice] = "Preencha o nome da casa."
      render "edit"
      return
    end
    if params[:user][:house_attributes] and params[:user][:house_attributes][:phone_number]
      @user.house.phone_number = params[:user][:house_attributes][:phone_number]
      @current_user.house.save
    end


    recruiter = User.find_by_id(params[:recruitment_id])
    if recruiter
      @user.recruiter = recruiter
      recruiter.points += 50
      recruiter.total_points += 50
      recruiter.save
      @user.is_fully_registered = true
    end

    if @user.save
      redirect_to edit_user_path(@user), :flash => { :notice => 'Perfil atualizado com sucesso!' }
      return
    else
      @user.house = House.new(name: house_name)
      @user.house.location = Location.new
      render "edit"
      return
    end







    # TODO: Why do we care about visitante?
    # if @current_user.role != "visitante"
    #   house_name = params[:user][:house_attributes][:name]
    #   house_address = params[:user][:location][:address] || ''
    #   house_neighborhood = params[:user][:location][:neighborhood] || ''
    #   house_profile_photo = params[:user][:house_attributes][:profile_photo] || ''
    # end



    # TODO: What is this notion of "Números do celular não coincidem"
    # if !user_params[:phone_number].empty? #and !user_profile_phone_number_confirmation.empty?
    #   #if user_profile_phone_number == user_profile_phone_number_confirmation
    #   if user_profile_phone_number != @user.phone_number
    #     @user.phone_number = user_profile_phone_number
    #     @user.is_fully_registered = true
    #   end
    #   #else
    #   #  @user = @current_user
    #   #  @confirm = 0
    #   #  flash[:alert] = "Números do celular não coincidem"
    #   #  redirect_to :back
    #   #  return
    #   #end
    # end

    # TODO: What do we do regarding this??
    # if !params[:user][:carrier].empty?# and !params[:carrier_confirmation].empty?
    #   #if params[:user][:carrier] == params[:carrier_confirmation]
    #   if @current_user.carrier != params[:user][:carrier]
    #     @user.carrier = params[:user][:carrier]
    #   end
    #   #else
    #   #  flash[:alert] = "Operadoras não coincidem."
    #   #  render "edit"
    #   #  return
    #   #end
    # end




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

  #----------------------------------------------------------------------------

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
      house_name = params[:user][:house_attributes][:name]
      street_type = params[:user][:location][:street_type]
      street_name = params[:user][:location][:street_name]
      street_number = params[:user] [:location][:street_number]
      house_address = street_type + " " + street_name + " " + street_number
      house_neighborhood = params[:user][:location][:neighborhood]
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

      location.latitude = params[:x]
      location.longitude = params[:y]

      location.neighborhood = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])

      if !location.save
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
end
