# -*- encoding : utf-8 -*-
module ApplicationHelper

  def partners
    return [
      ["Bill & Melinda Gates Foundation", "http://www.gatesfoundation.org", "partners/bill_melinda_gates.png"],
      ["CITRIS", "http://citris-uc.org", "partners/citris.png"],
      ["Inria", "http://www.inria.fr", "partners/inria.png"],
      ["Instituto Carlos Slim de la Salud", "http://www.salud.carlosslim.org/", "partners/slim.png"],
      # ["Instituto Pereira Passos", "http://ipprio.rio.rj.gov.br/", "partners/bill_melinda_gates.png"],
      # ["Redes da Maré", "http://redesdamare.org.br/", "partners/bill_melinda_gates.png"],
      # ["Secretaria Municipal de Saúde do Rio de Janeiro", "http://www.rio.rj.gov.br/web/sms", "partners/bill_melinda_gates.png"],
      ["UBS Optimus Foundation", "http://www.ubs.com/global/en/wealth_management/optimusfoundation.html", "partners/ubs.png"],
      ["UC Berkeley", "http://www.berkeley.edu/index.html", "partners/berkeley.png"],
      # ["UFRJ", "http://www.ufrj.br", "partners/bill_melinda_gates.png"]
    ]
  end

  def calculate_team_users(user)
    team_ids = user.teams.pluck(:id)
    users = User.joins(:team_memberships).where("team_memberships.team_id IN (?)", team_ids).order("username ASC")
    return users.uniq
  end

  def color_for_inspection_status(status)
    return "#e74c3c" if status == Inspection::Types::POSITIVE
    return "#f1c40f" if status == Inspection::Types::POTENTIAL
    return "#2ecc71"
  end

  def class_for_status(status)
    return "danger" if status == Inspection::Types::POSITIVE
    return "warning" if status == Inspection::Types::POTENTIAL
    return "success"
  end

  def default_navigation_hash
    return {
      :title => "", :description => "",
      :parent_navigation_path => nil, :parent_navigation_title => nil,
      :child_navigation_path  => nil, :child_navigation_title  => nil
    }
  end

  #----------------------------------------------------------------------------

  def chart_cookies
    return JSON.parse(cookies[:chart])
  end

  #----------------------------------------------------------------------------

  def blog_post_award_text
    return "+ #{User::Points::POST_CREATED.to_s} " + I18n.t("attributes.points").downcase
  end

  #----------------------------------------------------------------------------

  def logo_image
    if I18n.locale.to_s == User::Locales::PORTUGUESE
      image_tag("logo_pt.png", :id => "logo")
    else
      image_tag("denguechat_logo.jpg", :class => "img-rounded", :id => "logo")
    end
  end

  #----------------------------------------------------------------------------

  def self.temp_password_generator
    char_bank = ('0'..'9').to_a
    char_bank.shuffle.shuffle.shuffle!
    (1..8).collect{|a| char_bank[rand(char_bank.size)] }.join
  end

  #----------------------------------------------------------------------------

  def timestamp_in_metadata(timestamp)
    return "" if timestamp.blank?
    if (timestamp - Time.zone.now).abs < 3.days
      time_ago_in_words(timestamp) + " " + I18n.t("common_terms.ago")
    else
      return timestamp.strftime("%Y-%m-%d")
    end
  end

  #----------------------------------------------------------------------------

  def format_csv_timestamp(timestamp)
    return "" if timestamp.blank?
    return timestamp.strftime("%Y-%m-%d")
  end

  #----------------------------------------------------------------------------

  def format_timestamp(timestamp)
    return "" if timestamp.blank?
    return timestamp.strftime("%Y-%m-%d %H:%M")
  end

  #----------------------------------------------------------------------------

  def display_as_icon(boolean)
    if boolean
      return "<i class = 'fa fa-check' />".html_safe
    else
      return "<i class = 'fa fa-close' />".html_safe
    end
  end

end
