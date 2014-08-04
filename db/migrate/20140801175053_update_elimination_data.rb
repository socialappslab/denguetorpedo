class UpdateEliminationData < ActiveRecord::Migration
  def up
    EliminationType.order(:id).each do |et|
      puts "[ ] Migrating EliminationType with id = #{et.id}..."

      bs        = BreedingSite.find_or_create_by_description_in_pt( et.name )
      bs.points = et.points
      bs.save!

      puts "[ok] Successfully migrated EliminationType with id = #{et.id}!"
    end

    EliminationMethod.order(:id).each do |em|
      puts "[ ] Updating EliminationMethod with id = #{em.id}..."

      if em.elimination_type.blank?
        puts "[!] EliminationMethod has no associated EliminationType!"
        next
      end

      # Identify the corresponding breeding site from elimination type.
      breeding_site = BreedingSite.find_by_description_in_pt( em.elimination_type.name )
      raise "BreedingSite could not be found for elimination type = #{em.elimination_type.name}!" if breeding_site.nil?

      # Now update the columns, and save.
      em.breeding_site_id  = breeding_site.id
      em.description_in_pt = em.method
      em.save!

      puts "[ok] Successfully updated EliminationMethod with id = #{em.id}!"
    end
  end

  def down
  end
end
