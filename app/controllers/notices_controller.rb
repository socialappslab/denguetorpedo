# -*- encoding : utf-8 -*-
class NoticesController < ApplicationController
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
      liked  = false
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @news.id, :likeable_type => Notice.name)
      count += 1
      liked  = true

      Analytics.track( :user_id => @current_user.id, :event => "Liked a news snippet", :properties => {:news => @news.id}) if Rails.env.production?
    end

    render :json => {'count' => count.to_s, "liked" => liked} and return
  end

  #----------------------------------------------------------------------------
  # POST /notices/1/comment

  def comment
    redirect_to :back and return if ( @current_user.blank? || @news.blank? )

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @news.id, :commentable_type => Notice.name)
    c.content = params[:comment][:content]
    if c.save
      Analytics.track( :user_id => @current_user.id, :event => "Commented on a news snippet", :properties => {:news => @news.id}) if Rails.env.production?
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
