require "sidekiq"
require ::File.expand_path('../../modules/green_location_rankings',  __FILE__)

# This method runs every day and updates the Redis datastore responsible for
# calculating green location rankings.
class GreenLocationRankingsWorker
  include Sidekiq::Worker
  include GreenLocationRankings

  sidekiq_options :queue => :ranking, :retry => true, :backtrace => true

  def perform
    User.find_each do |u|
      GreenLocationRankings.add_score_to_user(u.green_locations.count, u)
    end

    GreenLocationRankingsWorker.perform_in(1.day)
  end
end
