# encoding: UTF-8

namespace :teams do
  desc "Set points for each team"
  task :set_points => :environment do
    Team.find_each do |team|
      team.update_column(:points, team.total_points)
    end
  end
end
