module ApplicationHelper

  def logo_image
    if I18n.locale.to_s == User::Locales::PORTUGUESE
      image_tag("logo_pt.png", :id => "logo", :style=> "z-index:3;")
    else
      image_tag("logo_es.png", :id => "logo", :style=> "z-index:3;")
    end
  end

  #----------------------------------------------------------------------------

  def self.temp_password_generator
    char_bank = ('0'..'9').to_a
    char_bank.shuffle.shuffle.shuffle!
    (1..8).collect{|a| char_bank[rand(char_bank.size)] }.join
  end

  #----------------------------------------------------------------------------

  def format_timestamp(timestamp)
    if (timestamp - Time.now).abs < 7.days
      time_ago_in_words(timestamp) + " " + I18n.t("common_terms.ago")
    else
      return timestamp.strftime("%d/%m/%Y")
    end
  end

  #----------------------------------------------------------------------------

end
