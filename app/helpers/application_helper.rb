module ApplicationHelper

  #----------------------------------------------------------------------------

  def self.temp_password_generator
    char_bank = ('0'..'9').to_a
    char_bank.shuffle.shuffle.shuffle!
    (1..8).collect{|a| char_bank[rand(char_bank.size)] }.join
  end

  #----------------------------------------------------------------------------

  # def elimination_selection(selection)
  #   selection_list = []
  #   if type = BreedingSite.find_by_description_in_pt(selection) || type = BreedingSite.find_by_description_in_es(selection)
  #
  #     type.elimination_methods.each do |method|
  #       selection_list << {:name=> method.id, :points => method.points,:id => method.id,
  #                          :display=> method.description + " (" + method.points.to_s + " pontos)"}
  #     end
  #
  #   end
  #
  #   return selection_list
  # end

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
