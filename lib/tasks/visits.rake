namespace :visits do
  task :convert_utc_to_cst => :environment do
    Time.zone = "UTC"
    Visit.where("date_part('hour', visited_at) = 0 AND date_part('minute', visited_at) = 0").find_each do |visit|
      visit.update_column(:visited_at, visit.visited_at + 6.hours)
    end
  end
end
