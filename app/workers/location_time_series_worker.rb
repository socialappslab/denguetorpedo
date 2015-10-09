require "sidekiq"
include LocationTimeSeries

# This method runs every day and updates the Redis datastore responsible for
# calculating green location rankings.
class LocationTimeSeriesWorker
  include Sidekiq::Worker
  include LocationTimeSeries

  sidekiq_options :queue => :timeseries, :retry => true, :backtrace => true

  def perform
    # NOTE: This is cumbersome, but we're going to delete the key before we run this.
    # This ensures that deleted locations/visits are properly flushed.
    $redis_pool.with do |redis|
      Neighborhood.find_each do |n|
        n.locations.find_each do |loc|
          redis.del(LocationTimeSeries.redis_key(n, loc))
        end
      end
    end

    Time.use_zone("America/Guatemala") do
      visits           = Visit.select("id, visited_at, location_id").where("location_id IS NOT NULL").order("visited_at ASC")
      visit_ids        = visits.pluck(:id)
      inspections_hash = Inspection.where(:visit_id => visit_ids).select([:visit_id, :identification_type]).group(:visit_id, :identification_type).count(:identification_type)

      visits.each do |visit|
        visit_date   = visit.visited_at
        location     = Location.find_by_id(visit.location_id)
        next if location.blank?
        neighborhood = location.neighborhood
        next if neighborhood.blank?

        visit_counts = inspections_hash.find_all {|k, v| k[0] == visit.id}
        pot_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POTENTIAL}
        pot_count    = pot_count[1] if pot_count
        pos_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POSITIVE}
        pos_count    = pos_count[1] if pos_count

        status = Inspection::Types::POSITIVE  if pos_count && pos_count > 0
        status = Inspection::Types::POTENTIAL if pot_count && pot_count > 0
        status = Inspection::Types::NEGATIVE if pot_count.blank? && pos_count.blank?

        LocationTimeSeries.add_status_to_visit_date(neighborhood, location, status, visit_date)
      end
    end
  end
end
