# encoding: UTF-8

class PrizesController < ApplicationController
  #-----------------------------------------------------------------------------

  before_filter :require_login, :except => :index

  #-----------------------------------------------------------------------------

  def index
    @user = current_user

    @prizes    = Prize.where(:is_badge => false).sort { |a, b| (a.expired? ? 1 : 0) <=> (b.expired? ? 1 : 0) }
    @available = Prize.where('stock > 0').where('expire_on >= ?', Time.new).where(:is_badge => false)
    @redeemed  = Prize.where('stock = 0 OR expire_on < ?', Time.new).where(:is_badge => false)

    @redetrel = House.where(name: "Rede Trel").first
    @redetrel = @redetrel.user if @redetrel

    @redeemed_counts = PrizeCode.count
    @medals = Prize.where(:is_badge => true).order(:cost)
    @filter = params[:filter]
    @max = params[:max]
    @sponsors = User.where(:role => User::Types::SPONSOR).where(is_blocked: false) #.sort { |x, y| x.house.name <=> y.house.name}

    if @filter == "pontos"
      if @max == "500"
        @filtered_prizes = Prize.where('cost <= 500').where(:is_badge => false)
      elsif @max == "1000"
        @filtered_prizes = Prize.where('cost > 500 AND cost < 1000').where(:is_badge => false)
      elsif @max == "5000"
        @filtered_prizes = Prize.where('cost > 1000 AND cost <5000').where(:is_badge => false)
      else
        @filtered_prizes = Prize.where('cost >= 5000').where(:is_badge => false)
      end
    elsif @filter == "badges"
      @filtered_prizes = Prize.where(:is_badge => true)
    elsif @filter == "individual"
      @filtered_prizes = Prize.where(:community_prize => false).where(:is_badge => false)
    elsif @filter == "community"
      @filtered_prizes = Prize.where(:community_prize => true).where(:is_badge => false)
    else
      @individual = Prize.where(:community_prize => false, :is_badge => false).sort { |a, b| (a.expired? ? 1 : 0) <=> (b.expired? ? 1 : 0) }
      @community  = Prize.where(:community_prize => true, :is_badge => false).sort { |a, b| a.available? <=> b.available? }
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @prizes }
    end
  end

  # GET /prizes/1
  # GET /prizes/1.json
  def show
    @prize = Prize.find(params[:id])
    @user = current_user

    if @prize.user.house.location
      @latitude = @prize.user.house.location.latitude || 0
      @longitude = @prize.user.house.location.longitude || 0
    else
      @latitude  = 0
      @longitude = 0
    end

    if @current_user.nil?
      @enoughPoints = false
    else
      @enoughPoints = @current_user.total_points >= @prize.cost ? true : false
    end

    respond_to do |format|
      format.html #{ render :partial => 'prizeview', :locals => {:user_id => 1}}
      format.json { render json: @prize }
    end
  end

  # GET /prizes/new
  # GET /prizes/new.json
  def new
    @prize = Prize.new
    # @user = current_user
    # @users = User.where(:role => "lojista").map { |user| user.display_name }
    @users = User.where(:role => "lojista").collect{ |user| [user.house.name, user.id]}
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @prize }
    end
  end

  #----------------------------------------------------------------------------
  # POST /prizes/1

  # TODO: The conditionals create an ugly nesting with too many special cases.
  # Furthermore, do we need the phone number???
  def new_prize_code
    @prize = Prize.find(params[:id])

    respond_to do |format|
      if @current_user.total_points >= @prize.cost
        if !@current_user.phone_number.nil?
          @prize_code = PrizeCode.create(:user_id => @current_user, :prize_id => @prize.id)
          format.html { redirect_to(@prize_code, :notice => "Prêmio resgatado! Vôce tem #{@current_user.total_points - @prize.cost} pontos".encode("UTF-8")) }
        else
          format.html { redirect_to(@prize, :alert => 'Need a valid phone number to redeem prize.') }
        end
      else
        format.html { redirect_to(@prize, :alert => "Vôce precisa de mais pontos. Vôce tem #{@current_user.total_points} pontos") }
      end
    end
  end

  #----------------------------------------------------------------------------
  # GET /prizes/1/edit

  def edit
    @prize = Prize.find(params[:id])
    @user = @current_user
    @users = User.where(:role => "lojista").collect{ |user| [user.house.name, user.id]}
  end

  #----------------------------------------------------------------------------
  # POST /prizes

  def create
    @prize = Prize.new(params[:prize])


    if @prize.save
      redirect_to @prize, notice: 'Prêmio criado com sucesso!'
    else
      @users = User.where(:role => "lojista").collect{ |user| [user.house.name, user.id]}
      render "new" and return
    end
  end

  #----------------------------------------------------------------------------

  # PUT /prizes/1
  # PUT /prizes/1.json
  def update
    @prize = Prize.find(params[:id])
    respond_to do |format|
      if @prize.update_attributes(params[:prize])
        format.html { redirect_to @prize, notice: 'O prêmio foi atualizado com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @prize.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prizes/1
  # DELETE /prizes/1.json
  def destroy
    @prize = Prize.find(params[:id])
    @prize.destroy

    respond_to do |format|
      format.html { redirect_to prizes_url }
      format.json { head :no_content }
    end
  end

  def admin
    @prizes = Prize.where(:is_badge => false)
    @badges = Prize.where(:is_badge => true).order(:cost)
  end

  def badges
    @badges = ["de_olho", "exterminador", "guerreiro", "saudavel", "cuido"]
  end
end
