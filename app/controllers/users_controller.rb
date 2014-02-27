#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController

  before_filter :require_login, :only => [:edit, :update, :index, :show]

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
  
  def update
    puts params

    if @current_user.role != "visitante"
      house_name = params[:user][:house_attributes][:name]
      house_address = params[:user][:location][:address] || ''
      house_neighborhood = params[:user][:location][:neighborhood] || ''
      house_profile_photo = params[:user][:house_attributes][:profile_photo] || ''
    end
    input_phone = params[:user][:phone_number]
    #Error message put
    if input_phone.length < 12
      flash[:alert] = "Número de celular invalido.  O formato correto é 0219xxxxxxxx."
      redirect_to :back and return
    end
    user_profile_phone_number = input_phone
    #user_profile_phone_number_confirmation = params[:phone_number_confirmation]
    user_profile_photo = params[:user][:profile_photo]
    user_email = params[:user][:email]
    display = params[:display]
    user_first_name = params[:user][:first_name]
    user_last_name = params[:user][:last_name]
    #user_middle_name = params[:user][:middle_name]
    user_nickname = params[:user][:nickname]


    @user = User.find(params[:id])
    if !user_profile_phone_number.empty? #and !user_profile_phone_number_confirmation.empty?
      #if user_profile_phone_number == user_profile_phone_number_confirmation
      if user_profile_phone_number != @user.phone_number
        @user.phone_number = user_profile_phone_number
        @user.is_fully_registered = true
      end
      #else
      #  @user = @current_user
      #  @confirm = 0
      #  flash[:alert] = "Números do celular não coincidem"
      #  redirect_to :back
      #  return
      #end
    end

    if params[:user][:carrier].empty?
      flash[:alert] = "Informe a sua operadora."
      redirect_to :back
      return
    end

    if !params[:user][:prepaid]
      flash[:alert] = "Marque pré ou pós-pago."
      redirect_to :back
      return
    end

    if !params[:user][:carrier].empty?# and !params[:carrier_confirmation].empty?
      #if params[:user][:carrier] == params[:carrier_confirmation]
      if @current_user.carrier != params[:user][:carrier]
        @user.carrier = params[:user][:carrier]
      end
      #else
      #  flash[:alert] = "Operadoras não coincidem."
      #  render "edit"
      #  return
      #end
    end



    @user.prepaid = params[:user][:prepaid]
    
    if user_profile_photo
      @user.profile_photo = user_profile_photo
    end
    
    if not user_email.blank?
      @user.email = user_email
    end

    @user.gender = params[:user][:gender]
    if house_name.blank?
      flash[:alert] = "Preencha o nome da casa."
      redirect_to :back
      return
    end

    # if a house exists with the same house name or house address, inform the user for confirmation
    if !house_name.blank? && House.find_by_name(house_name) && params[:user][:confirm].to_i == 0 && (!@user.house || (house_name != @user.house.name))
      @user.house ||= House.new
      @user.house.location ||= Location.new
      @user.house.location.street_type = params[:user][:location][:street_type]
      @user.house.location.street_name = params[:user][:location][:street_name]
      @user.house.location.street_number = params[:user][:location][:street_number]
      @user.house.location.neighborhood = Neighborhood.find_or_create_by_name(params[:user][:location][:neighborhood])
      @user.house.location.latitude ||= 0
      @user.house.location.longitude ||= 0
      @user.house.name = house_name
      @confirm = 1
      flash.now[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."

      render "edit"
    else
      @user.display = display
      @user.first_name = user_first_name
      #@user.middle_name = user_middle_name
      @user.last_name = user_last_name
      @user.nickname = user_nickname

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
    end 
  end
  
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
