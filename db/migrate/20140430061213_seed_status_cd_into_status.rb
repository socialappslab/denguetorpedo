# -*- encoding : utf-8 -*-
class SeedStatusCdIntoStatus < ActiveRecord::Migration
  def up
    Report.find_each do |r|
      next if r.status.present?

      if r.status_cd == 0
        r.update_attribute(:status, Report::STATUS[:reported])
      elsif r.status_cd == 1
        r.update_attribute(:status, Report::STATUS[:eliminated])
      end
    end
  end

  def down
  end
end
