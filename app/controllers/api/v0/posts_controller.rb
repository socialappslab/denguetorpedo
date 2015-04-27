# -*- encoding : utf-8 -*-
class API::V0::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user

  #----------------------------------------------------------------------------
  # DELETE /api/v0/posts/:id

  def destroy
    @post = @current_user.posts.find( params[:id] )

    if @post.destroy
      points = @current_user.total_points || 0
      @current_user.update_column(:total_points, points - User::Points::POST_CREATED)
      @current_user.teams.each do |team|
        team.update_column(:points, team.points - User::Points::POST_CREATED)
      end

      render :json => @post.as_json, :status => 200 and return
    else
      raise API::V0::Error.new(@post.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
end
