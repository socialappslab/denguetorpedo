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
  # GET /users/1/

  def show
    @user = User.find_by_id(params[:id])

    head :not_found and return if @user.nil?
    head :not_found and return if ( @user != @current_user && @user.role == User::Types::SPONSOR )

    @post         = Post.new
    @neighborhood = @user.neighborhood
    @house        = @user.house
    @badges       = @user.badges
    @user_posts   = @user.posts
    @reports      = @user.reports
    @coupons      = @user.prize_codes
    @notices      = @neighborhood.notices.order("updated_at DESC")

    # Find if user can redeem prizes.
    @prizes            = Prize.where('stock > 0').where('expire_on >= ? OR expire_on is NULL', Time.new).where(:is_badge => false)
    @redeemable_prizes = @prizes.where("cost < ?", @user.total_points)

    # See if the user has created any reports.


    # Load the community news feed. We explicitly limit activity to this month
    # so that we don't inadvertedly create a humongous array.
    # TODO: As activity on the site picks up, come back to rethink this inefficient
    # query.
    # TODO: Move the magic number '4.weeks.ago'
    if @current_user == @user
      neighborhood_reports = @neighborhood.reports.where("created_at > ?", 4.weeks.ago)
      neighborhood_reports = neighborhood_reports.find_all {|r| r.is_public? }

      # Now, let's load all the users, and their posts.
      neighborhood_posts = []
      @neighborhood.members.each do |m|
        user_posts = m.posts.where("created_at > ?", 4.weeks.ago)
        neighborhood_posts << user_posts
      end
      neighborhood_posts.flatten!

      @news_feed = (neighborhood_reports + neighborhood_posts + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
    else
      @news_feed = (@reports.to_a + @user_posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
    end

    respond_to do |format|
      format.html
      format.json { render json: {user: @user, house: @house, badges: @badges}}
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/new

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
  # GET /users/1

  def edit
    authorize!(:edit, @user) if @user != @current_user

    @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
    @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}
  end

  #----------------------------------------------------------------------------
  # PUT "/users/1

  def update
    # NOTE: These horrendous actions are a result of trying to save form information,
    # even when later information may not be correct.
    @user.update_attribute(:gender, params[:user][:gender])
    @user.update_attribute(:neighborhood_id, params[:user][:neighborhood_id])
    @user.update_attribute(:first_name, params[:user][:first_name])
    @user.update_attribute(:last_name, params[:user][:last_name])
    @user.update_attribute(:nickname, params[:user][:nickname])
    @user.update_attribute(:display, params[:user][:display])

    @user.update_attributes(params[:user].slice(:phone_number, :carrier, :prepaid)) if params[:cellphone] == "false"

    #--------------------------------------------------------------------------
    # If the user has written down an existing house, then we need to confirm
    # with them that that is the house they want to join.
    house = House.find_by_name(params[:user][:house_attributes][:name])
    if params[:house_name_confirmation].blank? && house.present? && @user.house_id != house.id
      @user.house = house

      @house_name_confirmation = true
      flash[:alert] = "Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar. Se não, clique cancelar e escolha outro nome de casa."

      @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
      @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}

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
    user_params = params[:user].slice(:profile_photo, :gender, :email, :display, :first_name, :last_name, :nickname, :neighborhood_id, :phone_number, :carrier, :prepaid)


    # TODO add in checks to rename or join existing house?
    # TODO should we allow users from neighborhood A join houses in neighborhood B
    # if house already exists, join existing house
    location = Location.find_by_street_type_and_street_name_and_street_number(
      params[:user][:house_attributes][:location_attributes][:street_type],
      params[:user][:house_attributes][:location_attributes][:street_name],
      params[:user][:house_attributes][:location_attributes][:street_number]
      )
    if location.nil?
      location = Location.new(params[:user][:house_attributes][:location_attributes])
      location.neighborhood_id = user_params[:neighborhood_id]
      location.save
    end

    if house.present?
      house.update_attribute(:location_id, location.id)
      @user.house = house
    else
      params[:user][:house_attributes].delete(:location_attributes)
      params[:user][:house_attributes].merge!(:location_id => location.id)

      if @user.house.present?
        @user.house.update_attributes(params[:user][:house_attributes]) #.name = params[:user][:house_attributes][:name]
      else
        @user.house = House.new(params[:user][:house_attributes])
      end
    end


    # if nickname is blank and display name includes nickname, change to firstlast
    if user_params[:nickname].blank?
      if user_params[:display].include? "nickname"
       user_params[:display] = "firstlast"
      end
    end

    #---------------------------------------------------------------------------
    # Handle carrier and prepaid errors.
    if params[:cellphone] == "false"
      # TODO: This is a hack to save the phone information in the case that user
      # registers with existing house name (the confirmation clears any temporary
      # variable results of cellphone information).

      # We still need this when the user object will be saved later in this method.
      # params[:user].merge!(:phone_number => "000000000000", :carrier => "xxx", :prepaid => true)
    else
      if params[:user][:carrier].blank?
        flash[:alert] = "Informe a sua operadora."

        @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
        @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}

        render "edit" and return
      elsif params[:user][:prepaid].blank?
        flash[:alert] = "Marque pré ou pós-pago."

        @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
        @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}

        render "edit" and return
      end
    end

    if @user.update_attributes(user_params)
      if @user.is_fully_registered == false
        # Identify the recruiter for this user.
        recruiter = User.find_by_id( params[:recruiter_id] )
        if recruiter
          @user.recruiter = recruiter
          recruiter.points       += 50
          recruiter.total_points += 50
          recruiter.save
        end
      end

      @user.update_attribute(:is_fully_registered, true)
    else
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
  # GET /users/1/buy_prize/1

  def buy_prize
    @user       = User.find(params[:id])
    @prize      = Prize.find(params[:prize_id])
    @prize_code = @user.generate_coupon_for_prize(@prize)
    render :partial => "prizes/prizeconfirmation", :locals => {:bought => @prize_code.present?}
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
