# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will populate
# all existing locations with the Mare neighborhood.
# DO NOT run this without permission from @dman7.

namespace :breeding_sites do
  desc "Reduce points by 10x for BreedingSites and EliminationMethods"
  task :reduce_points => :environment do
    BreedingSite.find_each do |bs|
      bs.points = bs.points / 10 if bs.points.present?
      bs.save!
    end

    EliminationMethod.find_each do |em|
      em.points = em.points / 10 if em.points.present?
      em.save!
    end
  end
end
