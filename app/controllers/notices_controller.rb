# encoding: utf-8
class NoticesController < ApplicationController
  #----------------------------------------------------------------------------

  before_filter :find_by_id, :only => [:like, :comment]

  #----------------------------------------------------------------------------

  # GET /notices
  # GET /notices.json
  def index
    @notices = Notice.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notices }
    end
  end

  # GET /notices/1
  # GET /notices/1.json
  def show
    @notice = Notice.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notice }
    end
  end

  # GET /notices/new
  # GET /notices/new.json
  def new
    @notice        = Notice.new
    @notice.date   = Time.now
    @neighborhoods = Neighborhood.all.collect{ |neighborhood| [neighborhood.name, neighborhood.id]}
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @notice }
    end
  end

  # GET /notices/1/edit
  def edit
    @neighborhoods = Neighborhood.all.collect{ |neighborhood| [neighborhood.name, neighborhood.id]}
    @notice = Notice.find(params[:id])
  end

  # POST /notices
  # POST /notices.json
  def create
    @notice = Notice.new(params[:notice])
    @notice.neighborhood_id = params[:notice][:neighborhood_id]

    respond_to do |format|
      if @notice.save
        format.html { redirect_to @notice, notice: 'Notícia criada com sucesso.' }
        format.json { render json: @notice, status: :created, location: @notice }
      else
        format.html { render action: "new" }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notices/1
  # PUT /notices/1.json
  def update
    @notice = Notice.find(params[:id])

    respond_to do |format|
      if @notice.update_attributes(params[:notice])
        @notice.save
        format.html { redirect_to @notice, notice: 'Notícia atualizado com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notices/1
  # DELETE /notices/1.json
  def destroy
    @notice = Notice.find(params[:id])
    @notice.destroy

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

  #----------------------------------------------------------------------------
  # POST /notices/1/like

  def like
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 if (@news.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @news.likes.find {|like| like.user_id == @current_user.id }
    if existing_like.present?
      existing_like.destroy
      count -= 1
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @news.id, :likeable_type => Notice.name)
      count += 1
    end

    render :json => {'count' => count.to_s} and return
  end

  #----------------------------------------------------------------------------
  # POST /notices/1/comment

  def comment
    redirect_to :back and return if ( @current_user.blank? || @news.blank? )

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @news.id, :commentable_type => Notice.name)
    c.content = params[:comment][:content]
    if c.save
      redirect_to :back, :notice => I18n.t("activerecord.success.comment.create") and return
    else
      redirect_to :back, :alert => I18n.t("attributes.content") + " " + I18n.t("activerecord.errors.comments.blank") and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def find_by_id
    @news = Notice.find(params[:id])
  end

  #----------------------------------------------------------------------------
end
