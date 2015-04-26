# -*- encoding : utf-8 -*-
module ReportsHelper
  def random_sponsors
    random_sponsors = []
    9.times do
      random_sponsors.push('home_images/sponsor'+(rand(5)+1).to_s+'.png')
    end
    random_sponsors
  end

  #----------------------------------------------------------------------------
  # Prize methods
  def inspection_award_text(report)
    return "+ #{User::Points::REPORT_SUBMITTED.to_s} " + I18n.t("attributes.points").downcase
  end


  def elimination_award_text(report)
    return "+0 points" if report.elimination_method.blank?
    return "+ #{report.elimination_method.points.to_s} " + I18n.t("attributes.points").downcase
  end

  def verification_award_text(report)
    return "+ #{User::Points::REPORT_VERIFIED.to_s} " + I18n.t("attributes.points").downcase
  end


end
