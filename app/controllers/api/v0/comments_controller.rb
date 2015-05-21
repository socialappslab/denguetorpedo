# -*- encoding : utf-8 -*-
class API::V0::CommentsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user

  #----------------------------------------------------------------------------
  # POST api/v0/comments/:id/like

  def like
    @comment = Comment.find(params[:id])
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 and return if (@comment.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @comment.likes.find {|like| like.user_id == @current_user.id }
    if existing_like.present?
      existing_like.destroy
      count -= 1
      liked  = false
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @comment.id, :likeable_type => Comment.name)
      count += 1
      liked  = true

      Analytics.track( :user_id => @current_user.id, :event => "Liked a comment", :properties => {:post => @comment.id}) if Rails.env.production?
    end

    render :json => {'count' => count.to_s, "liked" => liked} and return
  end

  #----------------------------------------------------------------------------
end
