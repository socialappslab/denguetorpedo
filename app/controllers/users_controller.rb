#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController

  #----------------------------------------------------------------------------

  before_filter :require_login, :only => [:edit, :update, :index, :show]
  before_filter :ensure_mare_neighborhood, :only => [:update]
  before_filter :identify_student, :only => [:edit, :update]

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

    @elimination_types = EliminationType.pluck(:name)
    reports_with_status_filtered = []
    locations = []

    respond_to do |format|
      format.html
      format.json { render json: {user: @user, house: @house, prizes: @prizes, badges: @badges}}
    end
  end

  #----------------------------------------------------------------------------

  def new
    @user = User.new
  end

  #----------------------------------------------------------------------------

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

  #----------------------------------------------------------------------------

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

  #----------------------------------------------------------------------------

  def edit
    @user = User.find(params[:id])
    @user.house ||= House.new
    @user.house.location ||= Location.new
    @user.house.location.latitude ||= 0
    @user.house.location.longitude ||= 0

    @display_options = [[@user.first_name + " " + @user.last_name,"firstlast"],
                        [@user.first_name,"first"]
                       ]

    # if nickname exists, allow display name as option
    @display_options += [[@user.nickname,"nickname"],
                         [@user.first_name + " " + @user.last_name + " (" + @user.get_nickname + ")","firstlastnickname"]
                        ] if @user.nickname.present?

    @highlightAccountItem = "nav_highlight"
    @verifiers = User.where(:role => "verificador").map { |verifier| {:value => verifier.id, :label => verifier.full_name}}.to_json
    @residents = User.residents.map { |resident| {:value => resident.id, :label => resident.full_name}}.to_json
    if @user != @current_user
      authorize! :edit, @user
    end
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
    @user = User.find(params[:id])

    #--------------------------------------------------------------------------
    # Handle carrier and prepaid errors.
    if params[:cellphone] == "false"
      # TODO: This is a hack to save the phone information in the case that user
      # registers with existing house name (the confirmation clears any temporary
      # variable results of cellphone information).
      @user.update_attribute(:phone_number, "000000000000")
      @user.update_attribute(:carrier, "xxx")
      @user.update_attribute(:prepaid, true)

      # We still need this when the user object will be saved later in this method.
      params[:user].merge!(:phone_number => "000000000000", :carrier => "xxx", :prepaid => true)
    else

      if params[:user][:carrier].blank?
        flash[:alert] = "Informe a sua operadora."
        redirect_to edit_user_path(@user) and return
      elsif params[:user][:prepaid].blank?
        flash[:alert] = "Marque pré ou pós-pago."
        redirect_to edit_user_path(@user) and return
      end

    end


    #--------------------------------------------------------------------------
    # If the user has written down an existing house, then we need to confirm
    # with them that that is the house they want to join.
    house = House.find_by_name(params[:user][:house_attributes][:name])
    if params[:house_name_confirmation].blank? && house.present? && @user.house_id != house.id
      @user.house = house

      @house_name_confirmation = true
      flash[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."

      @display_options = [[@user.first_name + " " + @user.last_name,"firstlast"],
                          [@user.first_name,"first"]
                         ]

      # if nickname exists, allow display name as option
      @display_options += [[@user.nickname,"nickname"],
                           [@user.first_name + " " + @user.last_name + " (" + @user.get_nickname + ")","firstlastnickname"]
                          ] if @user.nickname.present?

      render "edit" and return
    end


    # NOTE: This is essentially the old code boiled down. Before
    # saving it along with the user attributes, we do a quick query
    # to identify the house by its name. If it's present, we don't ask the user
    # to confirm, but instead we update the ID and the name, and save.
    # TODO: This makes Rails search for the house id in the *association*. As a
    # result, you get "Couldn't find House with ID = ..."
    # house = House.find_by_name(params[:user][:house_attributes][:name])
    # if house.present?
    #   params[:user][:house_attributes].merge!(:id => house.id, :name => house.name)
    # end

    # Now, let's find the neighborhood that the user has specified. If it actually
    # exists, then we'll update the house_attributes and pass it on to Rails's
    # saver.
    # NOTE: This is necessary in order for all validations to work.
    params[:user][:house_attributes].merge!(:neighborhood_id => params[:user][:neighborhood_id])

    #--------------------------------------------------------------------------
    # Update the user and the house
    user_params = params[:user].slice(:profile_photo, :gender, :email, :display, :first_name, :last_name, :nickname, :phone_number, :carrier, :prepaid, :neighborhood_id)


    # TODO add in checks to rename or join existing house?
    # TODO should we allow users from neighborhood A join houses in neighborhood B
    # if house already exists, join existing house
    if house.present?
      @user.house = house

    # user already has a house, update its name
    elsif @user.house.present?
      @user.house.name = params[:user][:house_attributes][:name]

    # else create a new house
    else
      @user.house = House.create(
                  :name=>params[:user][:house_attributes][:name],
                  :user=>@user,
                  :neighborhood_id => user_params[:neighborhood_id])

    end

    # if nickname is blank and display name includes nickname, change to firstlast
    if user_params[:nickname].blank?
      if user_params[:display].include? "nickname"
       user_params[:display] = "firstlast"
      end
    end


    if @user.update_attributes(user_params)
      @user.update_attribute(:is_fully_registered, true)

      # Identify the recruiter for this user.
      recruiter = User.find_by_id( params[:recruiter_id] )
      if recruiter
        @user.recruiter = recruiter
        recruiter.points       += 50
        recruiter.total_points += 50
        recruiter.save
      end
    else
      @display_options = [[@user.first_name + " " + @user.last_name,"firstlast"],
                          [@user.first_name,"first"]
                         ]

      # if nickname exists, allow display name as option
      @display_options += [[@user.nickname,"nickname"],
                           [@user.first_name + " " + @user.last_name + " (" + @user.get_nickname + ")","firstlastnickname"]
                          ] if @user.nickname.present?

      render "edit" and return
    end

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

    if location.save
      @user.house.update_attribute(:location_id, location.id)
    else
      flash[:notice] = "Insira um endereço válido."
      render "edit" and return
    end

    redirect_to edit_user_path(@user), :flash => { :notice => 'Perfil atualizado com sucesso!' }
  end


  #----------------------------------------------------------------------------

  def destroy
    @user = User.find(params[:id])

    # Destroy the user's house if he is the only one in the house.
    if @user.house && @user.house.members.count == 1
      @user.house.destroy
    end

    # Finally, let's delete the user.
    @user.destroy

    redirect_to users_url, :notice => "Usuário deletado com sucesso." and return
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

  #----------------------------------------------------------------------------

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

  #----------------------------------------------------------------------------

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

  private

  #----------------------------------------------------------------------------

  # TODO: We're disabling choosing other neighborhoods until we introduce
  # another neighborhood. See seeds.rb for more.
  def ensure_mare_neighborhood
    neighborhood = Neighborhood.find(params[:user][:neighborhood_id])
    raise "This neighborhood is not allowed" unless neighborhood.name == "Maré"
  end

  #----------------------------------------------------------------------------

  def identify_student
    @user = User.find(params[:id])
  end

  #----------------------------------------------------------------------------

end
