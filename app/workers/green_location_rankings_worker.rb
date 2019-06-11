require "sidekiq"
include GreenLocationRankings

# This method runs every day and updates the Redis datastore responsible for
# calculating green location rankings.
class GreenLocationRankingsWorker
  include Sidekiq::Worker
  include GreenLocationRankings

  sidekiq_options :queue => :ranking, :retry => true, :backtrace => true

  def self.perform
    User.find_each do |u|
      current_score = GreenLocationRankings.score_for_user(u)
      new_score     = u.green_locations.count

      # Generate a new post congratulating the user if their new score is higher
      # than last score.
      if current_score && new_score && new_score > current_score
        differential = (new_score - current_score).to_i
        points       = differential * User::Points::GREEN_HOUSE

        content = "¡Felicitaciones! <a href='#{Rails.application.routes.url_helpers.user_path(u)}'>@#{u.username}</a>, "
        content += "lograste #{differential} casas verdes y ganaste #{points} puntos! #puntos"

        post                 = Post.new
        post.content         = content
        post.user_id         = u.id
        post.neighborhood_id = u.neighborhood_id
        post.save!

        # Create notification for that particular user.
        Time.use_zone("America/Guatemala") do
          UserNotification.create(:user_id => u.id, :notification_id => post.id, :notification_type => "Post", :notified_at => Time.zone.now, :medium => UserNotification::Mediums::WEB)
        end
      end

      GreenLocationRankings.add_score_to_user(new_score, u)
    end

    GreenLocationRankingsWorker.perform_in(1.day)
  end
end
